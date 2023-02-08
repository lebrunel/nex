defmodule Nex do
  @moduledoc """
  Nex: an Elixir powered Nostr relay.
  """
  @relay_info Application.compile_env(:nex, :info, %{})
  @software "https://github.com/libitx/nex"
  @version Mix.Project.config[:version]
  @supported_nips [1, 2, 4, 9, 11, 12, 15, 16, 20, 22, 26, 28]

  @doc """
  Returns the [NIP-11](https://github.com/nostr-protocol/nips/blob/master/11.md)
  Relay Information Document map.
  """
  @spec relay_info(keyword() | map()) :: map()
  def relay_info(doc \\ @relay_info)
  def relay_info(doc) when is_list(doc),
    do: Enum.into(doc, %{}) |> relay_info()
  def relay_info(doc) when is_map(doc) do
    doc
    |> Map.take([:name, :description, :pubkey, :contact])
    |> Map.put(:supported_nips, @supported_nips)
    |> Map.put(:software, @software)
    |> Map.put(:version, @version)
  end
end
