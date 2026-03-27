defmodule Realtime.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Realtime.Registry},
      {Plug.Cowboy, scheme: :http, plug: Realtime.Router, options: [port: 4000]},
      Realtime.EventIngestor,
      Realtime.PresenceTracker,
      Realtime.RateTracker,
      Realtime.TopTracker,
      Realtime.SpamTracker,
      Realtime.EventQueue,
      Realtime.GuildSupervisor,
      Realtime.Redis,
      Realtime.Repo
    ]

    opts = [strategy: :one_for_one, name: Realtime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
