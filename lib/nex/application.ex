defmodule Nex.Application do
  @moduledoc false
  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Nex.Repo,
      {Bandit, plug: Nex.Plug, scheme: :http, options: [
        port: 4000,
        read_timeout: 30_000
      ]},
      {Phoenix.PubSub, name: Nex.PubSub},
    ]

    opts = [strategy: :one_for_one, name: Nex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
