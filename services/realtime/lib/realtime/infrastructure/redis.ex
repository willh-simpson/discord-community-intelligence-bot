defmodule Realtime.Infrastructure.Redis do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, conn} = Redix.start_link(System.get_env("REDIS_URL"))
    {:ok, conn}
  end

  def increment_messages(guild_id) do
    key = "messages:guild:#{guild_id}"

    GenServer.cast(__MODULE__, {:incr, key})
  end

  def handle_cast({:incr, key}, conn) do
    Redix.command(conn, ["INCR", key])
    {:noreply, conn}
  end
end
