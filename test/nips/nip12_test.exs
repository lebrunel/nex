defmodule Nex.Nips.Nip12Test do
  use Nex.TestCase
  use Plug.Test
  alias Nex.Messages.Event

  setup_all do
    key = K256.Schnorr.generate_random_signing_key()
    {:ok, key: key}
  end

  describe "Generic tag queries [NIP-12]" do
    test "subscribe to the x tag", %{key: key} do
      # Setup - create 2 tagged events
      create(build_event(%{
        content: "test1",
        tags: [
          ["x", "foo"],
        ]
      }, key))
      create(build_event(%{
        content: "test2",
        tags: [
          ["x", "bar"],
        ]
      }, key))

      assert Nex.Repo.aggregate(Event, :count, :nid) == 2

      # Subscribe to the x tag
      assert {:ok, ws} = ws_connect()
      assert {:ok, ws} = ws_push(ws, {:text, Jason.encode!(["REQ", "abc", %{"#x" => ["foo", "bar"]}])})

      # Recieve the event messages
      assert_receive event_messages
      assert {:ok, ws, events} = ws_decode(ws, event_messages)
      assert_in_delta length(events), 2, 1

      ws_close(ws)
    end
  end

end
