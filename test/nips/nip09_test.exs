defmodule Nex.Nips.Nip09Test do
  use Nex.TestCase
  import Ecto.Query, only: [from: 2]
  alias Nex.Messages.Event

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    {:ok, key: key}
  end

  describe "Event deletion [NIP-09]" do
    setup %{key: key} do
      %{id: id1} = create(build_event(key))
      %{id: id2} = create(build_event(key))
      %{id: id3} = create(build_event(key))
      {:ok, id1: id1, id2: id2, id3: id3}
    end

    test "delete event deletes the referenced events", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 3

      # Posts a event deletion
      assert {:ok, ws} = ws_connect()
      %{id: id} = event = build_event(%{
        kind: 5,
        content: "delete these please",
        tags: [
          ["e", ctx.id1],
          ["e", ctx.id2],
        ]
      }, ctx.key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      # Recieve a success msg back
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      ws_close(ws)

      # Check the deletion event is stored and tagged events deleted
      ids = Nex.Repo.all(from e in Event, select: [e.id]) |> Enum.map(&hd/1)
      assert length(ids) == 2
      assert id in ids
      refute ctx.id1 in ids
      refute ctx.id2 in ids
      assert ctx.id3 in ids
    end

    test "wont delete events when signed by different key", ctx do
      assert Nex.Repo.aggregate(Event, :count, :nid) == 3
      key = K256.Schnorr.generate_random_signing_key()

      # Posts a event deletion
      assert {:ok, ws} = ws_connect()
      %{id: id} = event = build_event(%{
        kind: 5,
        content: "delete these please",
        tags: [
          ["e", ctx.id1],
          ["e", ctx.id2],
        ]
      }, key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", event])})

      # Recieve a success msg back
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      ws_close(ws)
      assert Nex.Repo.aggregate(Event, :count, :nid) == 4
    end
  end
end
