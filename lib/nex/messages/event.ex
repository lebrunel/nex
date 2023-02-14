defmodule Nex.Messages.Event do
  @moduledoc """
  Nostr Event schema.

  See [NIP-01](https://github.com/nostr-protocol/nips/blob/master/01.md).
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Nex.Messages.{DBTag, Tag}
  alias Nex.Utils.DelegatedEvents

  @typedoc "Event"
  @type t() :: %__MODULE__{
    id: String.t(),
    pubkey: String.t(),
    delegator: String.t(),
    created_at: integer(),
    expires_at: integer(),
    kind: integer(),
    tags: list(Tag.t()),
    content: String.t(),
    sig: String.t(),
    replace_key: String.t(),
  }

  @replaceable_kinds    [0, 3, 41]
  @replaceable_range    10000..19999
  @ephemeral_range      20000..29999
  @parameterized_range  30000..39999

  @doc """
  Guard returning true if the given kind is of any replaceable event.
  """
  defguard is_replacable_kind(kind)
    when kind in @replaceable_kinds
    or kind in @replaceable_range
    or kind in @parameterized_range

  @doc """
  Guard returning true if the given kind is of any ephemeral event.
  """
  defguard is_ephemeral_kind(kind)
    when kind in @ephemeral_range

  @primary_key {:nid, :id, autogenerate: true}
  schema "events" do
    field :id, :string
    field :pubkey, :string
    field :delegator, :string
    field :created_at, :integer
    field :expires_at, :integer
    field :kind, :integer
    field :tags, {:array, {:array, :string}}, default: []
    field :content, :string, default: ""
    field :sig, :string
    field :replace_key, :string
    has_many :db_tags, DBTag, foreign_key: :event_nid, preload_order: [asc: :nid]

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Returns a changeset from the given params.

  This base changeset validates the presents and format of all fields, but does
  not verify the event ID or signature.
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(event, params \\ %{}) do
    event
    |> cast(params, [:id, :pubkey, :created_at, :kind, :tags, :content, :sig], empty_values: [nil])
    |> cast_database_tags()
    |> validate_required([:id, :pubkey, :created_at, :kind, :sig])
    |> validate_number(:kind, greater_than_or_equal_to: 0)
    |> validate_format(:id, ~r/^([a-f0-9]{2}){32}$/)
    |> validate_format(:pubkey, ~r/^([a-f0-9]{2}){32}$/)
    |> validate_format(:sig, ~r/^([a-f0-9]{2}){64}$/)
    |> validate_change(:created_at, &validate_field/2)
    |> put_delegation()
    |> put_expiration()
    |> put_replace_key()
  end

  @doc """
  Returns a changeset from the given params.

  As `f:changeset/2` but also verifies the event ID and signature.
  """
  @spec verify_changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def verify_changeset(event, params \\ %{}) do
    event
    |> changeset(params)
    |> validate_id()
    |> validate_pow()
    |> validate_sig()
  end

  @doc """
  Calculates the ID for the given event. Returns a hex-encoded ID.
  """
  @spec calc_id(Ecto.Schema.t()) :: String.t()
  def calc_id(%__MODULE__{} = e) do
    :crypto.hash(:sha256, id_preimage(e))
    |> Base.encode16(case: :lower)
  end

  @doc """
  Returns the ID preimage for the given event. Clients will sign this value.
  """
  @spec id_preimage(Ecto.Schema.t()) :: String.t()
  def id_preimage(%__MODULE__{} = e) do
    Jason.encode!([0, e.pubkey, e.created_at, e.kind, e.tags, e.content])
  end

  # Casts the list of tags to parmas to the DBTag schema.
  @spec cast_database_tags(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp cast_database_tags(changes) do
    params =
      changes
      |> get_change(:tags, [])
      |> Enum.map(&Tag.to_map/1)

    changes
    |> cast(%{db_tags: params}, [])
    |> cast_assoc(:db_tags)
  end

  # Validates a changeset field with the given value.
  @spec validate_field(atom(), any()) :: list()
  defp validate_field(:created_at, timestamp) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    min_delta = get_in(limits(), [:created_at, :min_delta])
    max_delta = get_in(limits(), [:created_at, :max_delta])

    cond do
      is_integer(min_delta) and min_delta > 0 and timestamp < now - min_delta ->
        [created_at: "can't be more than #{min_delta} seconds old"]
      is_integer(max_delta) and max_delta > 0 and timestamp > now + max_delta ->
        [created_at: "can't be more than #{max_delta} seconds in the future"]
      true ->
        []
    end
  end

  # Validates the ID in the changeset.
  @spec validate_id(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_id(%{valid?: false} = changes), do: changes
  defp validate_id(changes) do
    id = apply_changes(changes) |> calc_id()
    case get_field(changes, :id) do
      ^id -> changes
      _ -> add_error(changes, :id, "invalid ID")
    end
  end

  # Validates the ID contains configured proof if work (nip-13)
  defp validate_pow(%{valid?: false} = changes), do: changes
  defp validate_pow(changes) do
    id = get_field(changes, :id) |> Base.decode16!(case: :lower)
    pow = get_in(limits(), [:id, :min_pow_bits])

    case is_integer(pow) and match?(<<0::size(pow), _::bitstring>>, id) do
      true -> changes
      false -> add_error(changes, :id, "must have POW difficulty of #{pow}")
    end
  end

  # Validates the signature in the changeset.
  @dialyzer {:no_opaque, validate_sig: 1}
  @spec validate_sig(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_sig(%{valid?: false} = changes), do: changes
  defp validate_sig(changes) do
    msg = get_field(changes, :id) |> Base.decode16!(case: :lower)
    sig = get_field(changes, :sig) |> Base.decode16!(case: :lower)
    pubkey = get_field(changes, :pubkey) |> Base.decode16!(case: :lower)
    case K256.Schnorr.verify_message_digest(msg, sig, pubkey) do
      :ok -> changes
      _ -> add_error(changes, :sig, "invalid signature")
    end
  end

  # Finds valid delegation tags and puts the delegation into the changeset.
  @spec put_delegation(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_delegation(%{valid?: false} = changes), do: changes
  defp put_delegation(changes) do
    event = apply_changes(changes)
    with [_, pubkey, _, _] = tag <- Tag.find_by_name(event.tags, "delegation") do
      if DelegatedEvents.valid_delegated_event?(event, tag),
        do: put_change(changes, :delegator, pubkey),
        else: changes
    else
      _ -> changes
    end
  end

  # Finds valid expiration tags and puts the expiration timestamp into the changeset.
  @spec put_expiration(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_expiration(%{valid?: false} = changes), do: changes
  defp put_expiration(changes) do
    case Tag.find_by_name(get_field(changes, :tags), "expiration") do
      [_, expires_at] ->
        put_change(changes, :expires_at, String.to_integer(expires_at))
      _ ->
        changes
    end
  end

  # For replacable events puts a replaceable key into the changeset.
  @spec put_replace_key(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_replace_key(%{valid?: false} = changes), do: changes
  defp put_replace_key(changes) do
    case get_field(changes, :kind) do
      k when k in @replaceable_kinds or k in @replaceable_range ->
        replace_key = build_replace_key(changes, [:kind, :pubkey])
        put_change(changes, :replace_key, replace_key)
      k when k in @parameterized_range ->
        d = case Tag.find_by_name(get_field(changes, :tags), "d") do
          [_, value] when is_binary(value) -> value
          _ -> ""
        end
        replace_key = build_replace_key(changes, [:kind, :pubkey], [d])
        put_change(changes, :replace_key, replace_key)
      _ ->
        changes
    end
  end

  # Builds a repalce key string from the changeset.
  @spec build_replace_key(Ecto.Changeset.t(), list(atom()), list(String.t())) :: String.t()
  defp build_replace_key(changes, keys, vals \\ [])
  defp build_replace_key(_changes, [], vals), do: Enum.join(vals, ":")
  defp build_replace_key(changes, [key | keys], vals) do
    case get_field(changes, key) do
      nil -> build_replace_key(changes, keys, vals)
      val -> build_replace_key(changes, keys, [to_string(val) | vals])
    end
  end

  # Configured event limits
  defp limits() do
    Application.get_env(:nex, :limits, [])
    |> Keyword.get(:event, [])
  end


  defimpl Jason.Encoder do
    @impl true
    def encode(event, opts) do
      event
      |> Map.take([:id, :pubkey, :created_at, :kind, :tags, :content, :sig])
      |> Jason.Encode.map(opts)
    end
  end

end
