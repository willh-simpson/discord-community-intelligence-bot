defmodule Realtime.MixProject do
  use Mix.Project

  def project do
    [
      app: :realtime,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Realtime.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:httpoison, "~> 2.2"},
      {:jason, "~> 1.4"},
      {:redix, "~> 1.2"},
      {:postgrex, "~> 0.17"},
      {:ecto_sql, "~> 3.10"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix, "~> 1.7"}
    ]
  end
end
