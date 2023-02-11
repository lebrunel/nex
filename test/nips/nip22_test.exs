defmodule Nex.Nips.Nip22Test do
  use Nex.TestCase

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    set_min_max_delta(3600)
    on_exit(fn -> set_min_max_delta(0) end)
    {:ok, key: key}
  end

  def set_min_max_delta(n) do
    set_limits(fn limits ->
      put_in(limits, [:event, :created_at], [min_delta: n, max_delta: n])
    end)
  end

  describe "Command results [NIP-22]" do
    test "valid event returns OK true", ctx do
      assert {:ok, ws} = ws_connect()
      %{id: id} = event = build_event(%{content: "test"}, ctx.key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      assert {:ok, _ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
    end

    test "too old event returns OK false", ctx do
      timestamp =
        DateTime.utc_now()
        |> DateTime.add(-3660, :second)
        |> DateTime.to_unix()

      assert {:ok, ws} = ws_connect()
      %{id: id} = event = build_event(%{content: "test2", created_at: timestamp}, ctx.key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, false, "invalid: created_at"<>_] = Jason.decode!(res)

      ws_close(ws)
    end

    test "too futuristic event returns OK false", ctx do
      timestamp =
        DateTime.utc_now()
        |> DateTime.add(3660, :second)
        |> DateTime.to_unix()

      assert {:ok, ws} = ws_connect()
      %{id: id} = event = build_event(%{content: "test2", created_at: timestamp}, ctx.key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, false, "invalid: created_at"<>_] = Jason.decode!(res)

      ws_close(ws)
    end
  end

end
