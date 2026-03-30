defmodule Realtime.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Realtime.Registry},
      {Plug.Cowboy, scheme: :http, plug: Realtime.Web.Router, options: [port: 4000]},
      {Phoenix.PubSub, name: Realtime.PubSub},

      Realtime.Presence.Presence,
      Realtime.Presence.SessionTracker,
      Realtime.Presence.SessionMetrics,

      Realtime.Ingestion.EventIngestor,
      Realtime.Ingestion.EventQueue,

      Realtime.Analytics.RateTracker,
      Realtime.Analytics.TopTracker,
      Realtime.Analytics.SpamTracker,
      Realtime.Analytics.AggregationTracker,
      Realtime.Analytics.AnalyticsWorker,
      Realtime.Analytics.ChannelStats,
      Realtime.Analytics.Forecaster,

      Realtime.Moderation.SafetySignals,

      Realtime.Guilds.GuildSupervisor,

      Realtime.Infrastructure.Redis,
      Realtime.Infrastructure.Repo,
    ]

    opts = [strategy: :one_for_one, name: Realtime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
