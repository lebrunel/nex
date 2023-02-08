defmodule Nex.Messages.Msg do
  @moduledoc """
  Nostr Message schema.

  Use this module to decode and encode message strings passed over the websocket
  connection.

  Internally Nex passes messages around as tuples so we can take advantage
  of pattern matching.
  """

  @typedoc "Message"
  @type t() ::
    {:EVENT, map()} |
    {:REQ, String.t(), list(map())} |
    {:CLOSE, String.t()} |
    {:EVENT, String.t(), map()} |
    {:NOTICE, String.t()} |
    {:EOSE, String.t()} |
    {:OK, String.t(), boolean(), String.t()}

  @doc """
  Decodes the given message string into a tuple.
  """
  @spec decode(String.t()) :: {:ok, t()} | {:error, term()}
  def decode(message) when is_binary(message) do
    with {:ok, message} <- Jason.decode(message), do: decode_msg(message)
  end

  @doc """
  Encodes the given message tuple into a string.
  """
  @spec encode(t()) :: String.t()
  def encode(message) when is_tuple(message) do
    to_list(message) |> Jason.encode!()
  end

  # Decodes the message list into a tuple.
  defp decode_msg(["EVENT", event]), do: {:ok, {:EVENT, event}}
  defp decode_msg(["REQ", sub_id | filters]), do: {:ok, {:REQ, sub_id, filters}}
  defp decode_msg(["CLOSE", sub_id]), do: {:ok, {:CLOSE, sub_id}}
  defp decode_msg(_message), do: {:error, :invalid_message}

  # Encodes the message tuple into a list.
  defp to_list({:EVENT, sub_id, event}), do: ["EVENT", sub_id, event]
  defp to_list({:NOTICE, message}), do: ["NOTICE", message]
  defp to_list({:EOSE, sub_id}), do: ["EOSE", sub_id]
  defp to_list({:OK, event_id, success, message}),
    do: ["OK", event_id, success, message]
  defp to_list(_message) do
    raise "invalid message"
  end

end
