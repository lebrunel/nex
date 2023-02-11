defmodule Nex.Application do
  @moduledoc false
  use Application

  @port Application.compile_env(:nex, :http_port, 4000)

  @impl true
  def start(_type, _args) do
    children = [
      Nex.Repo,
      {Bandit, plug: Nex.Plug, scheme: :http, options: [
        port: @port,
        read_timeout: 30_000
      ]},
      {Phoenix.PubSub, name: Nex.PubSub},
    ]

    opts = [strategy: :one_for_one, name: Nex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
