import Config

# Configure database
config :nex, Nex.Repo,
  hostname: "localhost",
  database: "nex_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

if System.get_env("TEST_ENV") == "github" do
  config :nex, Nex.Repo,
    username: "postgres",
    password: "postgres"
end

# Configure limits
config :nex, :limits,
  connection: [
    rate_limits: [] # disbale limits in tests
  ],
  message: [
    rate_limits: [] # disbale limits in tests
  ]

# Print only warnings and errors during test
config :logger, level: :warn
