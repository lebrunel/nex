import Config

if config_env() == :prod do
  database_url = System.get_env("DATABASE_URL")
  http_port = System.get_env("PORT", "4000")

  config :nex,
    http_port: String.to_integer(http_port)

  config :nex, Nex.Repo,
    adapter: Ecto.Adapters.Postgres,
    pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10"))

  if database_url do
    config :nex, Nex.Repo, url: database_url
  else
    config :nex, Nex.Repo,
      hostname: System.fetch_env!("DB_HOST"),
      port: String.to_integer(System.get_env("DB_PORT", "5432")),
      username: System.fetch_env!("DB_USER"),
      password: System.fetch_env!("DB_PASSWORD"),
      database: System.fetch_env!("DB_NAME")
  end
end
