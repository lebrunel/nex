defmodule Nex.Nips.Nip33Test do
  use Nex.TestCase
  alias Nex.Messages.Event

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    {:ok, key: key}
  end

  describe "Parameterized Replaceable Events [NIP-33] with null tag" do
    setup %{key: key} do
      kind = Enum.random(30000..39999)
      event = create(build_event(%{kind: kind, content: "no tag"}, key))
      {:ok, kind: kind, event: event}
    end

    test "is replaced no d tag", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      %{id: id} = event = build_event(%{kind: ctx.kind, content: "r"}, ctx.key)

      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      assert nil == Nex.Repo.get(Event, ctx.event.nid)
    end

    test "is replaced with empty d tag", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      %{id: id} = event = build_event(%{kind: ctx.kind, content: "r", tags: [["d"]]}, ctx.key)

      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      assert nil == Nex.Repo.get(Event, ctx.event.nid)
    end

    test "is replaced with empty string d tag", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      %{id: id} = event = build_event(%{kind: ctx.kind, content: "r", tags: [["d", ""]]}, ctx.key)

      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      assert nil == Nex.Repo.get(Event, ctx.event.nid)
    end

    test "is replaced when first d tag is empty", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      %{id: id} = event = build_event(%{kind: ctx.kind, content: "r", tags: [["d", ""], ["d", "test"]]}, ctx.key)

      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      assert nil == Nex.Repo.get(Event, ctx.event.nid)
    end

    test "wont replace when d tag is non matching", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      %{id: id} = event = build_event(%{kind: ctx.kind, content: "r", tags: [["d", "test"]]}, ctx.key)

      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 2
      assert %Event{} = Nex.Repo.get(Event, ctx.event.nid)
    end
  end

  describe "Parameterized Replaceable Events [NIP-33] with d tag" do
    setup %{key: key} do
      kind = Enum.random(30000..39999)
      tag = :crypto.strong_rand_bytes(4) |> Base.encode16()
      event = create(build_event(%{kind: kind, content: "tagged", tags: [["d", tag]]}, key))
      {:ok, kind: kind, tag: tag, event: event}
    end

    test "is replaced with matching d tag", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      %{id: id} = event = build_event(%{kind: ctx.kind, content: "r", tags: [["d", ctx.tag]]}, ctx.key)

      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      assert nil == Nex.Repo.get(Event, ctx.event.nid)
    end

    test "is replaced with first matching d tag", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      %{id: id} = event = build_event(%{kind: ctx.kind, content: "r", tags: [["d", ctx.tag], ["d", "xyz"]]}, ctx.key)

      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      assert nil == Nex.Repo.get(Event, ctx.event.nid)
    end

    test "wont replace when d tag is non matching", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      %{id: id} = event = build_event(%{kind: ctx.kind, content: "r", tags: [["d", "test"]]}, ctx.key)

      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)
      ws_close(ws)

      assert Nex.Repo.aggregate(Event, :count, :nid) == 2
      assert %Event{} = Nex.Repo.get(Event, ctx.event.nid)
    end
  end

end
