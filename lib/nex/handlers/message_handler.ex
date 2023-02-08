defmodule Nex.Handlers.MessageHandler do
  @moduledoc """
  Message handler (implements `Nex.Handler`).
  """
  alias ETS.Set
  alias Nex.Socket
  alias Nex.Handlers.{
    EventHandler,
    SubscriptionHander,
  }

  @behaviour Nex.Handler

  @impl true
  def handle_item({:EVENT, event}, %Socket{} = socket) do
    EventHandler.handle_item(event, socket)
  end

  def handle_item({:REQ, sub_id, filters}, %Socket{} = socket) do
    SubscriptionHander.handle_item({sub_id, filters}, socket)
  end

  def handle_item({:CLOSE, sub_id}, %Socket{} = socket) do
    socket = update_in(socket.subs, & Set.delete!(&1, sub_id))
    {:ok, socket}
  end

  def handle_item(_msg, %Socket{} = socket) do
    send(socket.pid, {:message, {:NOTICE, "Message invalid: unhandled"}})
    {:ok, socket}
  end

end
