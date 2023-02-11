defmodule Nex.Nips.Nip26Test do
  use Nex.TestCase
  alias Nex.Messages

  setup_all do
    key1 = K256.Schnorr.generate_random_signing_key()
    key2 = K256.Schnorr.generate_random_signing_key()
    {:ok, key1: key1, key2: key2}
  end

  describe "Delegated event signing [NIP-26]" do
    test "valid delegated event can be filtered by signer or delegator", ctx do
      pubkey1 =
        ctx.key1
        |> K256.Schnorr.verifying_key_from_signing_key()
        |> elem(1)
        |> Base.encode16(case: :lower)

      pubkey2 =
        ctx.key2
        |> K256.Schnorr.verifying_key_from_signing_key()
        |> elem(1)
        |> Base.encode16(case: :lower)

      sig =
        "nostr:delegation:#{pubkey1}:kind=1"
        |> K256.Schnorr.create_signature(ctx.key2)
        |> elem(1)
        |> Base.encode16(case: :lower)

      tag = ["delegation", pubkey2, "kind=1", sig]
      %{id: id} = event = build_event(%{content: "test", tags: [tag]}, ctx.key1)
      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      assert {:ok, _ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      # Can filter event by signer or delegator
      assert [%{id: ^id}] = Messages.list_events([%{authors: [pubkey1]}])
      assert [%{id: ^id}] = Messages.list_events([%{authors: [pubkey2]}])
    end

    test "invalid delegated event (invalid sig) can only be filtered by signer ", ctx do
      pubkey1 =
        ctx.key1
        |> K256.Schnorr.verifying_key_from_signing_key()
        |> elem(1)
        |> Base.encode16(case: :lower)

      pubkey2 =
        ctx.key2
        |> K256.Schnorr.verifying_key_from_signing_key()
        |> elem(1)
        |> Base.encode16(case: :lower)

      sig =
        "nostr:delegation:#{pubkey1}:kind=xxx"
        |> K256.Schnorr.create_signature(ctx.key2)
        |> elem(1)
        |> Base.encode16(case: :lower)

      tag = ["delegation", pubkey2, "kind=1", sig]
      %{id: id} = event = build_event(%{content: "test", tags: [tag]}, ctx.key1)
      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      # Can filter event by signer only
      assert [%{id: ^id}] = Messages.list_events([%{authors: [pubkey1]}])
      assert [] = Messages.list_events([%{authors: [pubkey2]}])
    end

    test "invalid delegated event (invalid conditions) can only be filtered by signer ", ctx do
      pubkey1 =
        ctx.key1
        |> K256.Schnorr.verifying_key_from_signing_key()
        |> elem(1)
        |> Base.encode16(case: :lower)

      pubkey2 =
        ctx.key2
        |> K256.Schnorr.verifying_key_from_signing_key()
        |> elem(1)
        |> Base.encode16(case: :lower)

      sig =
        "nostr:delegation:#{pubkey1}:kind=100"
        |> K256.Schnorr.create_signature(ctx.key2)
        |> elem(1)
        |> Base.encode16(case: :lower)

      tag = ["delegation", pubkey2, "kind=100", sig]
      %{id: id} = event = build_event(%{content: "test", tags: [tag]}, ctx.key1)
      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      # Can filter event by signer only
      assert [%{id: ^id}] = Messages.list_events([%{authors: [pubkey1]}])
      assert [] = Messages.list_events([%{authors: [pubkey2]}])
    end
  end

end
