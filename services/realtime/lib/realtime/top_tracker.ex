defmodule Realtime.TopTracker do
  use GenServer

  def init(state), do: {:ok, state}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def ingest(event) do
    GenServer.cast(__MODULE__, {:event, event})
  end

  def track(user_id) do
    GenServer.cast(__MODULE__, {:track, user_id})
  end

  def top(limit \\ 10) do
    GenServer.call(__MODULE__, {:top, limit})
  end

  def handle_cast(
    {:event,
      %{
        "type" => "MESSAGE_CREATE",
        "user_id" => user_id
      }
    },
    state
  ) do
    now = System.system_time(:second)
    user = Map.get(state, user_id, %{count: 0, last_seen: now})
    new_user = %{user | count: user.count + 1, last_seen: now}

    {:noreply, Map.put(state, user_id, new_user)}
  end

  def handle_cast({:event, _}, state), do: {:noreply, state}

  def handle_cast({:track, user_id}, state) do
    state =
      Map.update(state, user_id, 1, fn count ->
        count + 1
      end)

    {:noreply, state}
  end

  def handle_call({:top, limit}, _from, state) do
    top_users =
      state
      |> Enum.sort_by(fn {_user, data} -> -data.count end)
      |> Enum.take(limit)
      |> Enum.map(fn {user, data} ->
        %{user: user, messages: data.count}
      end)

    {:reply, top_users, state}
  end
end
