defmodule Nex.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Nex.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 0.6"},
      {:cors_plug, "~> 3.0"},
      {:ecto_sql, "~> 3.9"},
      {:ets, "~> 0.9"},
      {:hammer, "~> 6.1"},
      {:jason, "~> 1.4"},
      {:k256, "~> 0.0.6"},
      {:mint_web_socket, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:plug, "~> 1.14"},
      {:postgrex, "~> 0.16"},
    ]
  end

  defp aliases do
    [
     "ecto.reset": ["ecto.drop", "ecto.create", "ecto.migrate"],
    ]
  end
end
