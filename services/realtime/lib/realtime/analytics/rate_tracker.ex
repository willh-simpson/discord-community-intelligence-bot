defmodule Realtime.Analytics.RateTracker do
  use GenServer

  @window_seconds 60 # e.g., messages per minute

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  # Public API
  def ingest(event) do
    GenServer.cast(__MODULE__, {:event, event})
  end

  def rate(user_id) do
    GenServer.call(__MODULE__, {:rate, user_id})
  end

  def handle_cast(
        {:event, %{"type" => "MESSAGE_CREATE", "user_id" => user_id}},
        state
      ) do
    now = System.system_time(:second)
    timestamps = Map.get(state, user_id, [])
    new_timestamps = [now | timestamps] |> Enum.filter(&(&1 > now - @window_seconds))

    {:noreply, Map.put(state, user_id, new_timestamps)}
  end

  def handle_cast({:event, _}, state), do: {:noreply, state}

  def handle_call({:rate, user_id}, _from, state) do
    count =
      state
      |> Map.get(user_id, [])
      |> length()

    {:reply, count, state}
  end
end
