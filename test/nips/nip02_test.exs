defmodule Nex.Nips.Nip02Test do
  use Nex.TestCase
  import Ecto.Query, only: [from: 2]
  alias Nex.Messages.{Event, DBTag}

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    {:ok, key: key}
  end

  describe "Contact lists [NIP-02]" do
    test "posting contact list deletes previous list", %{key: key} do
      %{nid: nid} = create(build_event(%{
        kind: 3,
        content: "",
        tags: [
          ["p", "abcde", "a", "b"],
          ["p", "12345", "a", "b"],
        ]
      }, key))

      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      assert Nex.Repo.aggregate(DBTag, :count, :nid) == 2

      # Posts a new contact list
      assert {:ok, ws} = ws_connect()
      %{id: id} = msg = build_event(%{
        kind: 3,
        content: "",
        tags: [
          ["p", "abcde", "a", "b"],
          ["p", "67890", "a", "b"],
          ["p", "xyzxx", "a", "b"],
        ]
      }, key)
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["EVENT", msg])})

      # Recieve a success msg back
      assert {:ok, ws, [{:text, res}]} = ws_receive(ws, 1)
      assert ["OK", ^id, true | _] = Jason.decode!(res)

      ws_close(ws)
      assert Nex.Repo.aggregate(Event, :count, :nid) == 1
      assert Nex.Repo.aggregate(DBTag, :count, :nid) == 3
      assert Nex.Repo.one(from e in Event, where: e.nid == ^nid) == nil
    end
  end

end
