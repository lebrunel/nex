defmodule Nex.Nips.Nip20Test do
  use Nex.TestCase

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    {:ok, key: key}
  end

  describe "Command results [NIP-20]" do
    test "valid event returns OK true", ctx do
      assert {:ok, ws} = ws_connect()
      %{id: id} = event = build_event(%{content: "test"}, ctx.key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      ws_close(ws)
    end

    test "invalid event returns OK false", ctx do
      assert {:ok, ws} = ws_connect()
      %{id: id} = event = build_event(%{content: "test", created_at: nil}, ctx.key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, false, "invalid:"<>_] = Jason.decode!(res)

      ws_close(ws)
    end
  end

end
