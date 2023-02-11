import Config

# Configure Nex app
config :nex,
  ecto_repos: [Nex.Repo],
  http_port: 4000

# Configure limits
config :nex, :limits,
  connection: [
    rate_limits: [
      {1,     10},  # 10 / sec
      {60,    50},  # 50 / min
      {3600,  300}, # 300 / hour
    ]
  ],
  message: [
    rate_limits: [
      {60,    240},   # 240 / min
      {3600,  3600},  # 3600 / hour
    ]
  ],
  event: [
    id: [
      # nip-13
      min_pow_bits: 0,
    ],
    pubkey: [
      whitelist: [],
      blacklist: [],
    ],
    kind: [
      whitelist: [],
      blacklist: [],
    ],
    created_at: [
      # nip-22
      min_delta: 0,
      max_delta: 0,
    ],
  ]

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
