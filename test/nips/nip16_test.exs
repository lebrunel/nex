defmodule Nex.Nips.Nip16Test do
  use Nex.TestCase
  alias Nex.Messages.Event

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    pubkey =
      K256.Schnorr.verifying_key_from_signing_key(key)
      |> elem(1)
      |> Base.encode16(case: :lower)
    {:ok, key: key, pubkey: pubkey}
  end

  describe "Event treatment [NIP-16]" do
    test "regular event is sent to subscribers and stored", ctx do
      create(build_event(ctx.key))
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1

      # Regular event
      kind = Enum.random(1000..9999)
      %{id: id} = event = build_event(%{kind: kind, content: "regular"}, ctx.key)

      # 1 - Connect and subscribe to user feed
      assert {:ok, ws1} = ws_connect()
      assert {:ok, ws1} = ws_push(ws1, {:text, Jason.encode!(["REQ", "abc", %{"authors" => [ctx.pubkey]}])})
      assert {:ok, ws1, _events} = ws_receive(ws1, 2)

      # 2 - Connect and publish
      assert {:ok, ws2} = ws_connect()
      assert {:ok, ws2} = ws_push(ws2, {:text, Jason.encode!(["EVENT", event])})

      # 2 - Receive conf
      assert {:ok, ws2, [{:text, res}]} = ws_receive(ws2, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      # 1- Receive event
      assert {:ok, ws1, [{:text, res}]} = ws_receive(ws1, 1)
      assert ["EVENT", "abc", %{"id" => ^id}] = Jason.decode!(res)

      ws_close(ws1)
      ws_close(ws2)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 2
    end

    test "replaceable event replaces previous event of same kind", ctx do
      # Replaceable events
      kind = Enum.random(10000..19999)
      create(build_event(%{kind: kind, content: "r1"}, ctx.key))
      %{id: id} = event = build_event(%{kind: kind, content: "r2"}, ctx.key)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 1

      # 1 - Connect and subscribe to user feed
      assert {:ok, ws1} = ws_connect()
      assert {:ok, ws1} = ws_push(ws1, {:text, Jason.encode!(["REQ", "abc", %{"authors" => [ctx.pubkey]}])})
      assert {:ok, ws1, _events} = ws_receive(ws1, 2)

      # 2 - Connect and publish
      assert {:ok, ws2} = ws_connect()
      assert {:ok, ws2} = ws_push(ws2, {:text, Jason.encode!(["EVENT", event])})

      # 2 - Receive conf
      assert {:ok, ws2, [{:text, res}]} = ws_receive(ws2, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      # 1- Receive event
      assert {:ok, ws1, [{:text, res}]} = ws_receive(ws1, 1)
      assert ["EVENT", "abc", %{"id" => ^id}] = Jason.decode!(res)

      ws_close(ws1)
      ws_close(ws2)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
    end

    test "ephemeral events are not stored", ctx do
      # Ephemeral events
      kind = Enum.random(20000..29999)
      %{id: id} = event = build_event(%{kind: kind, content: "r2"}, ctx.key)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 0

      # 1 - Connect and subscribe to user feed
      assert {:ok, ws1} = ws_connect()
      assert {:ok, ws1} = ws_push(ws1, {:text, Jason.encode!(["REQ", "abc", %{"authors" => [ctx.pubkey]}])})
      assert {:ok, ws1, _events} = ws_receive(ws1, 1)

      # 2 - Connect and publish
      assert {:ok, ws2} = ws_connect()
      assert {:ok, ws2} = ws_push(ws2, {:text, Jason.encode!(["EVENT", event])})

      # 1- Receive event
      assert {:ok, ws1, [{:text, res}]} = ws_receive(ws1, 1)
      assert ["EVENT", "abc", %{"id" => ^id}] = Jason.decode!(res)

      ws_close(ws1)
      ws_close(ws2)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 0
    end
  end

end
