defmodule Realtime.EventIngestor do
  use GenServer

  def init(state), do: {:ok, state}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def ingest(event) do
    GenServer.cast(__MODULE__, {:ingest, event})
  end

  def handle_cast({:ingest, event}, state) do
    Realtime.PresenceTracker.ingest(event)
    Realtime.RateTracker.ingest(event)
    Realtime.TopTracker.ingest(event)
    Realtime.SpamTracker.ingest(event)

    {:noreply, state}
  end
end
