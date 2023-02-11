defmodule Nex.Nips.Nip40Test do
  use Nex.TestCase
  alias Nex.Messages

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    {:ok, key: key}
  end

  describe "Expiration timestamp [NIP-40]" do
    test "expired events are not returned in filter queries", ctx do
      now = DateTime.utc_now() |> DateTime.to_unix()
      pubkey =
        K256.Schnorr.verifying_key_from_signing_key(ctx.key)
        |> elem(1)
        |> Base.encode16(case: :lower)

      %{id: id1} = e1 = build_event(%{tags: [["expiration", to_string(now-3600)]]}, ctx.key)
      %{id: id2} = e2 = build_event(%{tags: [["expiration", to_string(now+3600)]]}, ctx.key)

      # 1 - post events
      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", e1])})
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", e2])})

      # 2 - Receive conf
      assert {:ok, ws, msgs} = ws_receive(ws, 2)
      assert length(msgs) == 2
      ws_close(ws)

      events = Messages.list_events([%{authors: [pubkey]}])
      assert length(events) == 1
      assert id1 not in Enum.map(events, & &1.id)
      assert id2 in Enum.map(events, & &1.id)
    end
  end
end
