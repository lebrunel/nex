defmodule Nex.Socket do
  @moduledoc """
  Websocket handler implementing the `WebSock` behaviour.
  """
  require Logger
  alias ETS.Set
  alias Nex.Messages.{Filter, Msg}
  alias Nex.Handlers.MessageHandler
  alias Nex.RateLimiter

  @behaviour WebSock

  @heartbeat 20_000

  @limits %{
    connection: Application.compile_env(:nex, [:limits, :connection, :rate_limits], []),
    message: Application.compile_env(:nex, [:limits, :message, :rate_limits], []),
  }

  defstruct pid: nil, client_id: nil, client_ip: nil, subs: nil

  @type t() :: %__MODULE__{
    pid: pid(),
    client_id: String.t(),
    client_ip: String.t(),
    subs: Set.t()
  }

  @impl true
  def init(opts) do
    client_id = Keyword.get(opts, :client_id)
    client_ip = Keyword.get(opts, :client_ip)

    socket = %__MODULE__{
      pid: self(),
      client_id: client_id,
      client_ip: client_ip,
      subs: Set.new!(),
    }

    with :ok <- RateLimiter.limit("connection:#{client_ip}", @limits.connection) do
      Phoenix.PubSub.subscribe(Nex.PubSub, "events")
      Process.send_after(self(), :heartbeat, @heartbeat)
      Logger.info("WebSocket connected #{client_ip} (#{client_id})")

      {:ok, socket}

    else
      {:deny, _limit} ->
        # rate limited - disconnect
        {:stop, :normal, socket}
    end
  end

  @impl true
  def handle_in({message, opcode: :text}, socket) do
    with :ok <- RateLimiter.limit("message:#{socket.client_ip}", @limits.message),
         {:ok, message} <- Msg.decode(message)
    do
      MessageHandler.handle_item(message, socket)
    else
      {:deny, {scale_ms, rate}} ->
        send(socket.pid, {:message, {:NOTICE, "rate-limited: #{rate} message / #{scale_ms} ms exceeded"}})
        {:ok, socket}
      _ ->
        # invalid message - disconnect
        {:ok, socket}
    end

  end

  @impl true
  def handle_info({:event, sender, _event}, %__MODULE__{pid: pid} = socket)
    when sender == pid,
    do: {:ok, socket}

  def handle_info({:event, _pid, event}, socket) do
    Enum.each(Set.to_list!(socket.subs), fn {sub_id, filters} ->
      if Filter.match_any?(filters, event) do
        send(self(), {:message, {:EVENT, sub_id, event}})
      end
    end)
    {:ok, socket}
  end

  def handle_info({:message, message}, socket) when is_tuple(message) do
    {:push, {:text, Msg.encode(message)}, socket}
  end

  def handle_info({:message, messages}, socket) when is_list(messages) do
    messages = Enum.map(messages, & {:text, Msg.encode(&1)})
    {:push, messages, socket}
  end

  def handle_info(:heartbeat, socket) do
    Process.send_after(self(), :heartbeat, @heartbeat)
    {:push, {:ping, socket.client_id}, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    %{client_id: client_id, client_ip: client_ip} = socket
    Logger.info("WebSocket disconnected #{client_ip} (#{client_id})")
    Set.delete(socket.subs)
    :ok
  end

end
