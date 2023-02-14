defmodule Nex.MixProject do
  use Mix.Project

  def project do
    [
      app: :nex,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      name: "Nex",
      description: "Nex is a powerful and flexible Nostr relay written in Elixir.",
      source_url: "https://github.com/lebrunel/nex",
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      package: pkg(),
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
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:hammer, "~> 6.1"},
      {:jason, "~> 1.4"},
      {:k256, "~> 0.0.6"},
      {:mint_web_socket, "~> 1.0", only: :test},
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

  defp docs do
    [
      main: "Nex"
    ]
  end

  defp pkg do
    [
      name: "nex",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/lebrunel/nex"
      }
    ]
  end
end
