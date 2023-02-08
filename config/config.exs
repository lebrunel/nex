import Config

# Configure Nex app
config :nex,
  ecto_repos: [Nex.Repo]

# Configure Hammer backend
config :hammer,
  backend: {Hammer.Backend.ETS, [
    expiry_ms: 3_600_000,
    cleanup_interval_ms: 600_000
  ]}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time [$level] $message $metadata\n"

import_config "#{config_env()}.exs"
