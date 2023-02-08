defmodule Nex.Messages.Filter do
  @moduledoc """
  Nostr Message schema.

  This module is used both to cast raw filter maps into an internal format, and
  also to match events against those filters.
  """
  alias Nex.Messages.Event

  @typedoc "Filter"
  @type t() :: %{
    optional(:ids) => list(String.t()),
    optional(:authors) => list(String.t()),
    optional(:kinds) => list(integer()),
    optional(:since) => integer(),
    optional(:until) => integer(),
    optional(:limit) => integer(),
    optional(:tags) => list(tag()),
  }

  @typedoc "Tag"
  @type tag() :: {String.t(), list(String.t())}

  @doc """
  Casts the map of filter consitions into a structured map.

  Specfically Nex turns tag conditions (any filter beginning with "#") into
  a list of tuples for simpler query building and filtering.
  """
  @spec cast(map()) :: t()
  def cast(params) when is_map(params) do
    with %{} <- params do
      [:ids, :authors, :kinds, :since, :until, :limit, :tags]
      |> Enum.reduce(%{}, & cast_field(&2, &1, params))
    else
      _ -> %{}
    end
  end

  @doc """
  Returns true if any of the list of filters matches the given event.
  """
  @spec match_any?(list(t()), Event.t()) :: boolean()
  def match_any?(filters, %Event{} = event) when is_list(filters),
    do: Enum.any?(filters, & match_event?(&1, event))

  @doc """
  Returns true if the filter matches the given event.
  """
  @spec match_event?(t(), Event.t()) :: boolean()
  def match_event?(f, %Event{} = event) when is_map(f) do
    results = []
    |> match_any_like(event.id, f[:ids])
    |> match_any_like(event.pubkey, f[:authors])
    |> match_any_exact(event.kind, f[:kinds])
    |> match_num(event.created_at, :gte, f[:since])
    |> match_num(event.created_at, :lte, f[:until])
    |> match_tags(event.tags, f[:tags])

    length(results) > 0 && Enum.all?(results, & &1)
  end

  @doc """
  Returns true if the filter is valid (not empty!)
  """
  @spec valid?(t()) :: boolean()
  def valid?(filter) when is_map(filter) do
    filter
    |> Map.keys()
    |> Enum.any?(& &1 in [:ids, :authors, :kinds, :since, :until, :limit, :tags])
  end
  def valid?(_filter), do: false

  # Casts the given field and value to a filter
  @spec cast_field(t(), atom(), map()) :: t()
  defp cast_field(filter, :ids, %{"ids" => val}) when is_list(val),
    do: Map.put(filter, :ids, Enum.filter(val, &is_binary/1))

  defp cast_field(filter, :authors, %{"authors" => val}) when is_list(val),
    do: Map.put(filter, :authors, Enum.filter(val, &is_binary/1))

  defp cast_field(filter, :kinds, %{"kinds" => val}) when is_list(val),
    do: Map.put(filter, :kinds, Enum.filter(val, &is_integer/1))

  defp cast_field(filter, :since, %{"since" => val}) when is_integer(val),
    do: Map.put(filter, :since, val)

  defp cast_field(filter, :until, %{"until" => val}) when is_integer(val),
    do: Map.put(filter, :until, val)

  defp cast_field(filter, :limit, %{"limit" => val}) when is_integer(val),
    do: Map.put(filter, :limit, val)

  defp cast_field(filter, :tags, params) do
    tags =
      params
      |> Enum.filter(fn {tag, val} -> match?("#" <> _, tag) and is_list(val) end)
      |> Enum.map(fn {"#" <> tag, val} -> {tag, val} end)

    if length(tags) > 0, do: Map.put(filter, :tags, tags), else: filter
  end

  defp cast_field(filter, _key, _params), do: filter

  # Checks if any value in the haystack begins with the needle
  @spec match_any_like(list(boolean()), String.t(), list(String.t())) :: list(boolean())
  defp match_any_like(results, needle, haystack) when is_list(haystack) do
    res = needle in haystack or Enum.any?(haystack, & String.starts_with?(needle, &1))
    [res | results]
  end
  defp match_any_like(results, _needle, _haystack), do: results

  # Checks if any value in the haystack equals the needle
  @spec match_any_exact(list(boolean()), String.t(), list(String.t())) :: list(boolean())
  defp match_any_exact(results, needle, haystack) when is_list(haystack),
    do: [needle in haystack | results]
  defp match_any_exact(results, _needle, _haystack), do: results

  # Compares the value against the filter number
  @spec match_num(list(boolean()), integer(), atom(), integer()) :: list(boolean())
  defp match_num(results, val, :gte, filter) when is_integer(filter),
    do: [val >= filter | results]
  defp match_num(results, val, :lte, filter) when is_integer(filter),
    do: [val <= filter | results]
  defp match_num(results, _val, _op, _filter), do: results

  # Matches tags
  @spec match_tags(list(boolean()), list(list(String.t())), list(tag())) :: list(boolean())
  defp match_tags(results, tags, filter) when is_list(tags) and is_list(filter) do
    res = Enum.all?(filter, fn {name, vals} ->
      Enum.any?(tags, fn [tag_name, tag_value | _] ->
        tag_name == name && tag_value in vals
      end)
    end)
    [res | results]
  end
  defp match_tags(results, _tags, _filter), do: results

end
