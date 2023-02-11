defmodule Nex.Nips.Nip13Test do
  use Nex.TestCase
  alias Nex.Messages.Event

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    set_min_pow_bits(20)
    on_exit(fn -> set_min_pow_bits(0) end)
    {:ok, key: key}
  end

  def set_min_pow_bits(n) do
    set_limits(fn limits -> put_in(limits, [:event, :id, :min_pow_bits], n) end)
  end

  @pow_event %Event{
    id: "000006d8c378af1779d2feebc7603a125d99eca0ccf1085959b307f64e5dd358",
    pubkey: "a48380f4cfcc1ad5378294fcac36439770f9c878dd880ffa94bb74ea54a6f243",
    created_at: 1651794653,
    kind: 1,
    tags: [
      ["nonce", "776797", "20"]
    ],
    content: "It's just me mining my own business",
    sig: "284622fc0a3f4f1303455d5175f7ba962a3300d136085b9566801bc2e0699de0c7e31e44c81fb40ad9049173742e904713c3594a1da0fc5d2382a25c11aba977"
  }

  describe "Proof of work [NIP-13]" do
    test "event with sufficient POW is valid" do
      assert %{valid?: true} = Event.verify_changeset(@pow_event)
    end

    test "event with insufficient POW is invalid", ctx do
      assert %{valid?: false} = changes = Event.verify_changeset(build_event(ctx.key))
      assert %{id: [msg]} = errors_on(changes)
      assert String.match?(msg, ~r/POW difficulty/)
    end
  end

end
