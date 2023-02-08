defmodule Nex.Utils.DelegatedEvents do
  @moduledoc """
  Utility function to assist finding and verifying delegation tags used in
  [NIP-26](https://github.com/nostr-protocol/nips/blob/master/26.md).
  """
  alias Nex.Messages.{Event, Tag}

  @doc """
  Returns true if the Event contains a delegation tag.
  """
  @spec delegated_event?(Event.t()) :: boolean()
  def delegated_event?(%Event{tags: tags}) do
    Tag.find_by_name(tags, "delegation") |> is_list()
  end

  @doc """
  Returns true if the Event contains a valid delegation tag.

  A delegation tag is valid if it's conditions match the event it is contained
  in, and the signature verifies.
  """
  @spec valid_delegated_event?(Event.t()) :: boolean()
  def valid_delegated_event?(%Event{tags: tags} = event) do
    with ["delegation", _key, _conds, _sig] = tag <- Tag.find_by_name(tags, "delegation") do
      valid_delegated_event?(event, tag)
    else
      _ -> false
    end
  end

  @spec valid_delegated_event?(Event.t(), list(String.t())) :: boolean()
  def valid_delegated_event?(
    %Event{} = event,
    [_, pubkey, conditions, sig]
  ) do
    message = "nostr:delegation:#{event.pubkey}:#{conditions}"
    check_conditions(conditions, event) and verify_sig(sig, message, pubkey)
  end

  # Checks the conditions string against the given Event.
  @spec check_conditions(String.t(), Event.t()) :: boolean()
  defp check_conditions(conditions, e) do
    conditions
    |> String.split("&")
    |> Enum.all?(& check_condition(&1, e))
  end

  # Checks a single condition against the given Event.
  @spec check_condition(String.t(), Event.t()) :: boolean()
  defp check_condition("kind=" <> val, e), do: e.kind == String.to_integer(val)
  defp check_condition("created_at<" <> val, e), do: e.created_at < String.to_integer(val)
  defp check_condition("created_at>" <> val, e), do: e.created_at > String.to_integer(val)
  defp check_condition(_condition, _e), do: false

  # Verifies the signature against the given message and pubkey.
  @dialyzer {:no_opaque, verify_sig: 3}
  @spec verify_sig(binary(), binary(), binary()) :: boolean()
  defp verify_sig(sig, msg, pubkey) do
    with {:ok, sig} <- Base.decode16(sig, case: :lower),
         {:ok, pubkey} <- Base.decode16(pubkey, case: :lower),
         :ok <- K256.Schnorr.verify_message(msg, sig, pubkey)
    do
      true
    else
      _ -> false
    end
  end

end
