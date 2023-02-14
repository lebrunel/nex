defmodule Nex.Messages.Tag do
  @moduledoc """
  Nostr Tag schema.

  A Nostr Tag is simply a list of strings. This module defines the type and
  provides convinience functions for finding tags or conveting a tag to a map
  of parameters.
  """

  @typedoc "Tag"
  @type t() :: list(String.t())

  @doc """
  Filters the list of tags by the given name.
  """
  @spec filter_by_name(list(t()), String.t()) :: t() | nil
  def filter_by_name(tags, name) when is_list(tags) do
    Enum.filter(tags, fn [tag_name | _] -> tag_name == name end)
  end

  @doc """
  Finds the first tag from the list by the given name.
  """
  @spec find_by_name(list(t()), String.t()) :: t() | nil
  def find_by_name(tags, name) when is_list(tags) do
    Enum.find(tags, fn [tag_name | _] -> tag_name == name end)
  end

  @doc """
  Returns the first two elements of the tag as a map of name and value.
  """
  @spec to_map(t()) :: map()
  def to_map([name]), do: %{name: name}
  def to_map([name, value | _]), do: %{name: name, value: value}

end
