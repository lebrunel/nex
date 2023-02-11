defmodule Nex.TestCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Nex.TestCase.Helpers
      import Nex.Fixtures
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Nex.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.mode(Nex.Repo, {:shared, self()})
  end

  defmodule Helpers do
    alias Mint.{HTTP, WebSocket}

    def errors_on(changeset) do
      Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
        Regex.replace(~r"%{(\w+)}", message, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)
    end

    def set_limits(callback \\ fn limits -> limits end) do
      conf = Application.get_env(:nex, :limits)
      |> then(callback)
      Application.put_env(:nex, :limits, conf)
    end

    def ws_connect() do
      {:ok, conn} = HTTP.connect(:http, "localhost", 4000)
      {:ok, conn, ref} = WebSocket.upgrade(:ws, conn, "/", [])
      assert_receive http_get_message
      {:ok, conn, [{:status, ^ref, status}, {:headers, ^ref, resp_headers}, {:done, ^ref}]} = WebSocket.stream(conn, http_get_message)
      {:ok, conn, socket} = WebSocket.new(conn, ref, status, resp_headers)
      {:ok, {conn, ref, socket}}
    end

    def ws_close({conn, _ref, _socket} = ws) do
      ws_push(ws, :close)
      #assert_receive close_message
      #assert {:ok, {conn, ^ref, _socket}, [{:close, _, _}]} = ws_decode(ws, close_message)
      HTTP.close(conn)
    end

    def ws_push({conn, ref, socket}, message) do
      {:ok, socket, data} = WebSocket.encode(socket, message)
      {:ok, conn} = WebSocket.stream_request_body(conn, ref, data)
      {:ok, {conn, ref, socket}}
    end

    def ws_receive(ws, count, messages \\ []) do
      %{socket: port} = elem(ws, 0)
      assert_receive {:tcp, ^port, _} = raw_messages, 1000
      assert {:ok, ws, msgs} = ws_decode(ws, raw_messages)
      messages = messages ++ msgs
      if length(messages) < count do
        ws_receive(ws, count, messages)
      else
        {:ok, ws, messages}
      end
    end

    def ws_decode({conn, ref, socket}, raw_message) do
      {:ok, conn, [{:data, ^ref, data}]} = WebSocket.stream(conn, raw_message)
      {:ok, socket, messages} = WebSocket.decode(socket, data)
      {:ok, {conn, ref, socket}, messages}
    end
  end
end
