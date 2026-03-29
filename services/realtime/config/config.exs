import Config

config :realtime, Realtime.Infrastructure.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: 10

config :realtime, Realtime.Infrastructure.Redis,
  url: System.get_env("REDIS_URL") || "redis://localhost:6379"
