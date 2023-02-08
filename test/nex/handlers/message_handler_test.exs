defmodule Nex.Handlers.MessageHandlerTest do
  use Nex.TestCase
  alias Nex.Handlers.MessageHandler
  alias Nex.Socket
  alias ETS.Set

  setup do
    subs = Set.put!(Set.new!(), {"test1", [%{}]})
    socket = %Socket{pid: self(), subs: subs}
    {:ok, socket: socket}
  end

  test "EVENT event returns ok tuple", %{socket: socket} do
    assert {:ok, ^socket} = MessageHandler.handle_item({:EVENT, %{}}, socket)
  end

  test "REQ event returns ok tuple", %{socket: socket} do
    assert {:ok, ^socket} = MessageHandler.handle_item({:REQ, "test2", [%{}]}, socket)
  end

  test "CLOSE event with known sub removes subscription", %{socket: socket} do
    assert {:ok, socket} = MessageHandler.handle_item({:CLOSE, "test1"}, socket)
    assert {:ok, nil} = Set.get(socket.subs, "test1")
  end

  test "CLOSE event with unknown sub takes no action", %{socket: socket} do
    assert {:ok, socket} = MessageHandler.handle_item({:CLOSE, "test2"}, socket)
    assert {:ok, {"test1", [%{}]}} = Set.get(socket.subs, "test1")
  end

  test "unrecognised event sends notice", %{socket: socket} do
    assert {:ok, ^socket} = MessageHandler.handle_item(["foo", "bar"], socket)
    assert_received {:message, {:NOTICE, _}}
  end
end
