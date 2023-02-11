defmodule Nex.Nips.Nip15Test do
  use Nex.TestCase

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    {:ok, key: key}
  end

  describe "End of stored events notice [NIP-15]" do
    setup %{key: key} do
      %{id: id1} = create(build_event(key))
      %{id: id2} = create(build_event(key))
      %{id: id3} = create(build_event(key))
      {:ok, id1: id1, id2: id2, id3: id3}
    end

    test "event send at end of all stroed events", ctx do
      pubkey =
        K256.Schnorr.verifying_key_from_signing_key(ctx.key)
        |> elem(1)
        |> Base.encode16(case: :lower)

      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["REQ", "abc", %{"authors" => [pubkey]}])})

      assert {:ok, ws, events} = ws_receive(ws, 4)
      assert length(events) == 4
      assert {:text, res} = List.last(events)
      assert ["EOSE", "abc"] = Jason.decode!(res)

      ws_close(ws)
    end

  end
end
