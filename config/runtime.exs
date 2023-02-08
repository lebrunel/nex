import Config

if config_env() == :prod do
  config :nex, Nex.Repo,
    adapter: Ecto.Adapters.Postgres,
    url: System.fetch_env!("DATABASE_URL"),
    pool_size: String.to_integer(System.get_env("DATABASE_POOL_SIZE", "10"))
end
