defmodule Nex.Fixtures do
  alias Nex.Messages.{Event, DBTag}

  @dialyzer {:nowarn_function, build_event: 1, build_event: 2}

  def build_event(params \\ %{}, privkey) do
    {:ok, pubkey} = K256.Schnorr.verifying_key_from_signing_key(privkey)
      rand = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)

      event = Map.merge(%Event{
        pubkey: Base.encode16(pubkey, case: :lower),
        created_at: DateTime.utc_now() |> DateTime.to_unix(),
        kind: 1,
        tags: [],
        content: "test-#{rand}",
      }, Map.take(params, [:created_at, :kind, :tags, :content]))
      |> then(fn %Event{tags: tags} = event ->
        Map.put(event, :db_tags, Enum.map(tags, &build_tag/1))
      end)

      {:ok, sig} = K256.Schnorr.create_signature(Event.id_preimage(event), privkey)

      event
      |> Map.put(:id, Event.calc_id(event))
      |> Map.put(:sig, Base.encode16(sig, case: :lower))
  end

  def build_tag() do
    pubkey = Base.encode16(:crypto.strong_rand_bytes(32), case: :lower)
    build_tag(["p", pubkey])
  end

  def build_tag([name, value | _]) do
    %DBTag{name: name, value: value}
  end

  def create(schema), do: Nex.Repo.insert!(schema)

end
