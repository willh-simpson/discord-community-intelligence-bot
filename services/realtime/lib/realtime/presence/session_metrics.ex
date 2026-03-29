defmodule Realtime.Presence.SessionMetrics do
  use GenServer

  def init(_), do: {:ok, %{}}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def record(user, duration) do
    GenServer.cast(__MODULE__, {:record, user, duration})
  end

  def handle_cast({:record, user, duration}, state) do
    updated =
      Map.update(state, user, [duration], fn d ->
        [duration | d]
      end)

    {:noreply, updated}
  end
end
