defmodule Nex.Plug do
  @moduledoc """
  Nex Plug module.

  There are two ways for Nex to be run:

  1. As a standalone application (see Readme)
  2. As an enpoint embedded within another Plug or Phoenix router

  ```
  forward "/nex", to: Nex.Plug
  ```
  """
  require EEx
  use Plug.Builder

  plug CORSPlug
  plug :nex

  @version Mix.Project.config[:version]

  # Compile the homepage to a function
  EEx.function_from_file(:defp, :hompage, "priv/static/index.html.eex", [:version])

  @doc """
  Nex Plug function - handles all HTTP and websocket connections.

  Websocket requests are handled by the the `Nex.Socket` module.

  HTTP requests with the `content-type` header of `"application/nostr+json"`
  responds with a [NIP-11](https://github.com/nostr-protocol/nips/blob/master/11.md)
  Relay Information Document.
  """
  @spec nex(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def nex(conn, _opts) do
    cond do
      websocket?(conn) ->
        opts = [
          client_id: get_client_id(conn),
          client_ip: get_client_ip(conn)
        ]
        upgrade_adapter(conn, :websocket, {Nex.Socket, opts, []})

      relay_info?(conn) ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(200, Jason.encode!(Nex.relay_info()))

      true ->
        send_resp(conn, 200, hompage(@version))
    end
  end

  # Returns true for websocket requests
  @spec websocket?(Plug.Conn.t()) :: boolean()
  defp websocket?(conn) do
    connection = get_req_header(conn, "connection")
    upgrade = get_req_header(conn, "upgrade")
    Enum.any?(connection, & String.match?(&1, ~r/^upgrade$/i))
    and Enum.any?(upgrade, & String.match?(&1, ~r/^websocket$/i))
  end

  # Returns true for NIP-11 requests
  @spec relay_info?(Plug.Conn.t()) :: boolean()
  defp relay_info?(conn) do
    "application/nostr+json" in get_req_header(conn, "accept")
  end

  # Extracts the websocket key as a client ID
  @spec get_client_id(Plug.Conn.t()) :: String.t() | nil
  defp get_client_id(conn) do
    with [key] <- get_req_header(conn, "sec-websocket-key"),
         {:ok, key} <- Base.decode64(key)
    do
      Base.encode16(key, case: :lower)
    else
      _ -> nil
    end
  end

  # Extracts the request IP address
  @spec get_client_ip(Plug.Conn.t()) :: String.t()
  defp get_client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip] -> ip
      _ -> :inet.ntoa(conn.remote_ip) |> to_string()
    end
  end
end
