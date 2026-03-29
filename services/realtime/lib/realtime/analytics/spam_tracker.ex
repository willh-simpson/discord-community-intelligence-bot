defmodule Realtime.Analytics.SpamTracker do
  use GenServer

  @window_seconds 60
  @threshold 5 # e.g., more than 5 messages in last minute = spam

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  # Public API
  def ingest(event) do
    GenServer.cast(__MODULE__, {:event, event})
  end

  def spammers() do
    GenServer.call(__MODULE__, :spammers)
  end

  # Track user message timestamps
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

  def handle_call(:spammers, _from, state) do
    spammers =
      state
      |> Enum.filter(fn {_user, timestamps} ->
        length(timestamps) > @threshold
      end)
      |> Enum.map(fn {user, timestamps} ->
        %{
          user: user,
          messages: length(timestamps),
          window: @window_seconds,
          last_message: Enum.max(timestamps)
        }
      end)

    {:reply, spammers, state}
  end
end
