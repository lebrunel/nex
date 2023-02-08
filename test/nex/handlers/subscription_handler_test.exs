defmodule Nex.Handlers.SubscriptionHanderTest do
  use Nex.TestCase
  alias Nex.Handlers.SubscriptionHander
  alias Nex.Socket
  alias ETS.Set

  setup do
    socket = %Socket{pid: self(), subs: Set.new!()}
    {:ok, socket: socket}
  end

  test "REQ event adds a valid subscription", %{socket: socket} do
    assert {:ok, socket} = SubscriptionHander.handle_item({"test1", [%{"ids" => ["a"]}]}, socket)
    assert {:ok, [%{ids: ["a"]}]} = Set.get_element(socket.subs, "test1", 2)
  end

  test "REQ event adds sanitised valid subscription", %{socket: socket} do
    assert {:ok, socket} = SubscriptionHander.handle_item({"test1", [%{"a" => 1, "ids" => ["a"]}, %{a: 1}]}, socket)
    assert {:ok, filters} = Set.get_element(socket.subs, "test1", 2)
    assert is_list(filters)
    assert length(filters) == 1
    assert hd(filters) == %{ids: ["a"]}
  end

  test "REQ event ignores invalid subscription", %{socket: socket} do
    assert {:ok, socket} = SubscriptionHander.handle_item({"test1", [%{a: 2}]}, socket)
    assert {:ok, nil} = Set.get(socket.subs, "test1")
    assert_received {:message, {:NOTICE, _}}
  end

end
