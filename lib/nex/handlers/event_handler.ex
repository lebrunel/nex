defmodule Nex.Handlers.EventHandler do
  @moduledoc """
  Event handler (implements `Nex.Handler`).
  """
  alias Nex.{Messages, Socket}
  alias Nex.Messages.Event
  import Event, only: [is_replacable_kind: 1, is_ephemeral_kind: 1]

  @behaviour Nex.Handler

  @impl true
  def handle_item(event_params, %Socket{} = socket) when is_map(event_params) do
    case event_params["kind"] do
      k when is_replacable_kind(k) ->
        handle_replaceable_event(event_params, socket)

      k when is_ephemeral_kind(k) ->
        handle_ephemeral_event(event_params, socket)

      5 ->
        handle_delete_event(event_params, socket)

      _ ->
        handle_default_event(event_params, socket)
    end
  end

  # Replaceable events (persist and drop previous events)
  defp handle_replaceable_event(event_params, %Socket{} = socket) do
    with {:ok, %{event: event}} <- Messages.insert_event_and_drop_previous(event_params) do
      send_success(event, socket)
      notify_sockets(event, socket)
    else
      {:error, _, changes, _} -> send_error(changes, socket)
    end

    {:ok, socket}
  end

  # Ephemeral events (not persisted)
  defp handle_ephemeral_event(event_params, %Socket{} = socket) do
    changes = Event.changeset(%Event{}, event_params)
    if changes.valid? do
      event = Ecto.Changeset.apply_changes(changes)
      notify_sockets(event, socket)
    else
      send_error(changes, socket)
    end

    {:ok, socket}
  end

  # Handle event deletion
  defp handle_delete_event(event_params, %Socket{} = socket) do
    with {:ok, %{event: event}} <- Messages.insert_event_and_drop_tagged(event_params) do
      send_success(event, socket)
      notify_sockets(event, socket)
    else
      {:error, changes} -> send_error(changes, socket)
    end

    {:ok, socket}
  end

  # Default event handler
  def handle_default_event(event_params, %Socket{} = socket) do
    with {:ok, event} <- Messages.insert_event(event_params) do
      send_success(event, socket)
      notify_sockets(event, socket)
    else
      {:error, changes} -> send_error(changes, socket)
    end

    {:ok, socket}
  end

  # Notify all sockets that a new event has been recieved.
  defp notify_sockets(%Event{} = event, %Socket{} = socket) do
    Phoenix.PubSub.broadcast(Nex.PubSub, "events", {:event, socket.pid, event})
  end

  # Sends a success message back to the current socket.
  defp send_success(%Event{} = event, %Socket{} = socket) do
    msg = if Map.get(event, :nid) == nil, do: "duplicate:", else: ""
    send(socket.pid, {:message, {:OK, event.id, true, msg}})
  end

  # Sends an error message back to the current socket.
  defp send_error(changes, %Socket{} = socket) do
    event_id = Ecto.Changeset.get_field(changes, :id)
    reason = get_first_error(changes)
    send(socket.pid, {:message, {:OK, event_id, false, "invalid: #{reason}"}})
  end

  # Gets the first error from the invalid changeset.
  defp get_first_error(changes) do
    errors = get_error_map(changes)
    key = hd(Map.keys(errors))
    "#{Atom.to_string(key)} #{hd(errors[key])}"
  end

  # Reduces all changeset errors into a human readable form.
  defp get_error_map(changes) do
    Ecto.Changeset.traverse_errors(changes, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

end
