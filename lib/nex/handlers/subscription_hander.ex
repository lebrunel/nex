defmodule Nex.Handlers.SubscriptionHander do
  @moduledoc """
  Subscription handler (implements `Nex.Handler`).
  """
  alias ETS.Set
  alias Nex.{Messages, Socket}
  alias Nex.Messages.Filter

  @behaviour Nex.Handler

  @impl true
  def handle_item({sub_id, filters}, %Socket{} = socket)
    when is_binary(sub_id)
    and is_list(filters)
  do
    filters =
      filters
      |> Enum.map(&Filter.cast/1)
      |> Enum.filter(&Filter.valid?/1)
      |> Enum.uniq()

    cond do
      Enum.all?(filters, &Enum.empty?/1) ->
        send(socket.pid, {:message, {:NOTICE, "Subscription rejected: invalid"}})
        {:ok, socket}

      Set.match!(socket.subs, {sub_id, filters}) |> length() > 0 ->
        send(socket.pid, {:message, {:NOTICE, "Subscription rejected: duplicate"}})
        {:ok, socket}

      true ->
        messages =
          filters
          |> Messages.list_events()
          |> Enum.map(& {:EVENT, sub_id, &1})

        send(socket.pid, {:message, messages})
        send(socket.pid, {:message, {:EOSE, sub_id}})

        socket = update_in(socket.subs, & Set.put!(&1, {sub_id, filters}))
        {:ok, socket}
    end
  end

end
