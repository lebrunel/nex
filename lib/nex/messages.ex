defmodule Nex.Messages do
  @moduledoc """
  Messages context module.

  This is the main interface for storing and retrieving events from the
  database.
  """
  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Nex.Repo
  alias Nex.Messages.{Event, Filter, DBTag}

  @default_limit 100

  @doc """
  Inserts the given event parameters to the database.
  """
  @spec insert_event(map()) :: {:ok, Event.t()} | {:error, Changeset.t()}
  def insert_event(params \\ %{}) do
    %Event{}
    |> Event.verify_changeset(params)
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Inserts the given event parameters to the database, and deletes previous
  events of the same kind from the same author.

  Use this for storing contact lists and metadata events.
  """
  @spec insert_event_and_drop_previous(map()) ::
    {:ok, any()} |
    {:error, any()} |
    {:error, Multi.name(), any(), map()}
  def insert_event_and_drop_previous(params \\ %{}) do
    changes = Event.verify_changeset(%Event{}, params)
    Multi.new()
    |> Multi.insert(:event, changes, on_conflict: :nothing)
    |> Multi.delete_all(:drop, fn %{event: %{nid: nid, replace_key: replace_key}} ->
      where(Event, [e], e.nid < ^nid and e.replace_key == ^replace_key)
    end)
    |> Repo.transaction()
  end

  @doc """
  Inserts the given event parameters to the database, and deletes events
  referenced in `e` tags.

  Use this for [NIP-09](https://github.com/nostr-protocol/nips/blob/master/09.md)
  events.
  """
  @spec insert_event_and_drop_tagged(map()) ::
    {:ok, any()} |
    {:error, any()} |
    {:error, Multi.name(), any(), map()}
  def insert_event_and_drop_tagged(params \\ %{}) do
    changes = Event.verify_changeset(%Event{}, params)
    Multi.new()
    |> Multi.insert(:event, changes, on_conflict: :nothing)
    |> Multi.delete_all(:drop, fn %{event: %{pubkey: pubkey, kind: 5, db_tags: tags}} ->
      ids =
        tags
        |> Enum.filter(& &1.name == "e")
        |> Enum.map(& &1.value)

      where(Event, [e], e.id in ^ids and e.pubkey == ^pubkey and e.kind != 5)
    end)
    |> Repo.transaction()
  end

  @doc """
  Lists events by the given list of filters. Multiple conditions in the same
  filter are `AND` conditions. Multiple filters are `OR` conditions.

  See `Nex.Messages.Filter` for details fo a valid filter.
  """
  @spec list_events(list(Filter.t())) :: list(Event.t())
  def list_events(filters \\ [])

  def list_events([]), do: []

  def list_events(filters) when is_list(filters) do
    filters
    |> filter_query()
    |> Repo.all()
  end

  @doc """
  As `f:list_events/1` but streams the query results. The given callback
  function is invoked for each event row.
  """
  @spec stream_events(list(Filter.t()), (Event.t() -> any)) :: list()
  def stream_events(filters \\ [], callback)

  def stream_events([], _callback), do: :ok

  def stream_events(filters, callback) when is_list(filters) and is_function(callback, 1) do
    stream =
      filters
      |> filter_query()
      |> Repo.stream()

    res = Repo.transaction(fn ->
      stream
      |> Stream.each(callback)
      |> Stream.run()
    end)

    with {:ok, _} <- res, do: :ok
  end

  # Builds the query for a single filter.
  defp filter_query([f | filters]) do
    filters
    |> Enum.map(&filter_query/1)
    |> Enum.reduce(filter_query(f), & union(&2, ^&1))
    |> distinct(true)
    |> maybe_limit(f[:limit])
    |> order_by(fragment("created_at DESC"))
  end

  defp filter_query(filter) when is_map(filter) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    from(e in Event, as: :events)
    |> join(:left, [e], t in assoc(e, :db_tags))
    |> where(^filter_by(:ids, filter))
    |> where(^filter_by(:authors, filter))
    |> where(^filter_by(:kinds, filter))
    |> where(^filter_by(:since, filter))
    |> where(^filter_by(:until, filter))
    |> where(^filter_by(:tags, filter))
    |> where([e], is_nil(e.expires_at) or e.expires_at > ^now)
  end

  # Adds a dynamic query for the given filter key.
  defp filter_by(:ids, %{ids: vals}) when is_list(vals) do
    Enum.reduce(vals, dynamic(false), fn val, q ->
      dynamic([e], ^q or like(e.id, ^"#{val}%"))
    end)
  end

  defp filter_by(:authors, %{authors: vals}) when is_list(vals) do
    Enum.reduce(vals, dynamic(false), fn val, q ->
      dynamic([e], ^q or like(e.pubkey, ^"#{val}%") or like(e.delegator, ^"#{val}%"))
    end)
  end

  defp filter_by(:kinds, %{kinds: vals}) when is_list(vals) do
    dynamic([e], e.kind in ^vals)
  end

  defp filter_by(:since, %{since: val}) when is_integer(val) do
    dynamic([e], e.created_at >= ^val)
  end

  defp filter_by(:until, %{until: val}) when is_integer(val) do
    dynamic([e], e.created_at <= ^val)
  end

  defp filter_by(:tags, %{tags: tags}) when is_list(tags) do
    tag_query = DBTag
    |> select([t], count(t.nid))
    |> where([t], parent_as(:events).nid == t.event_nid)
    |> where(^filter_all_tags(tags))

    dynamic(subquery(tag_query) >= ^length(tags))
  end

  defp filter_by(_key, _filter), do: []

  # Adds a dynamic tag query.
  defp filter_all_tags(tags) when is_list(tags) do
    Enum.reduce(tags, dynamic(false), fn {tag, vals}, q ->
      dynamic([t], ^q or (t.name == ^tag and t.value in ^vals))
    end)
  end

  # Limits the query results by the given amount.
  defp maybe_limit(qry, val) when is_integer(val) and val <= @default_limit * 2,
    do: limit(qry, ^val)
  defp maybe_limit(qry, _val), do: limit(qry, @default_limit)

end
