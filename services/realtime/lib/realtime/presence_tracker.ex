defmodule Realtime.PresenceTracker do
  use GenServer

  @window_seconds 3_600 # 1 hour

  # GenServer callback
  def init(state), do: {:ok, state}

  # public API endpoints
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def ingest(event) do
    GenServer.cast(__MODULE__, {:event, event})
  end

  def active_users(channel_id) do
    GenServer.call(__MODULE__, {:active_users, channel_id})
  end

  def sessions(channel_id) do
    GenServer.call(__MODULE__, {:sessions, channel_id})
  end

  # message create -> update presence
  def handle_cast(
    {:event,
      %{
        "type" => "MESSAGE_CREATE",
        "channel_id" => channel_id,
        "user_id" => user_id
      }
    },
    state
  ) do
    now = System.system_time(:second)
    channel = Map.get(state, channel_id, %{})

    user =
      case Map.get(channel, user_id) do
        nil ->
          %{
            session_start: now,
            last_seen: now,
            messages: 1
          }

        existing ->
          %{
            existing
            | last_seen: now,
              messages: existing.messages + 1
          }
      end

    new_channel = Map.put(channel, user_id, user)
    new_state = Map.put(state, channel_id, new_channel)

    {:noreply, new_state}
  end

  def handle_cast({:event, _}, state), do: {:noreply, state}

  # active users within last hour
  def handle_call({:active_users, channel_id}, _from, state) do
    now = System.system_time(:second)

    channel =
      state
      |> Map.get(cahnnel_id, %{})
      |> Enum.filter(fn {_user, data} ->
        now - data.last_seen <= @@window_seconds
      end)
      |> Enum.into(%{})
    count = map_size(channel)

    new_state = Map.put(state, channel_id, channel)

    {:reply, count, new_state}
  end

  # session metrics
  def handle_call({:sessions, channel_id}, _from, state) do
    now = System.system_time(:second)

    sessions =
      state
      |> Map.get(channel_id, %{})
      |> Enum.map(fn {user, data} ->
        %{
          user: user,
          duration: now - data.session_start,
          messages: data.messages
        }
      end)

    {:reply, sessions, state}
  end
end
