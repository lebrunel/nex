import Config

# Configure database
config :nex, Nex.Repo,
  hostname: "localhost",
  database: "nex_dev",
  pool_size: 10

# Do not include metadata nor timestamps in development logs
config :logger, :console,
  format: "[$level] $message $metadata\n"
