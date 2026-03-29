defmodule Realtime.Presence.SessionTracker do
  use GenServer

  def init(_), do: {:ok, %{}}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def user_joined(user) do
    GenServer.cast(__MODULE__, {:join, user})
  end

  def user_left(user) do
    GenServer.cast(__MODULE__, {:leave, user})
  end

  def handle_cast({:join, user}, state) do
    {:noreply, Map.put(state, user, System.system_time(:second))}
  end

  def handle_cast({:leave, user}, state) do
    {start, state} = Map.pop(state, user)

    if start do
      duration = System.system_time(:second) - start
      Realtime.Presence.SessionMetrics.record(user, duration)
    end

    {:noreply, state}
  end
end
