defmodule Realtime.Guilds.GuildProcess do
  use GenServer

  def start_link(guild_id) do
    GenServer.start_link(__MODULE__, guild_id)
  end

  def init(guild_id) do
    Registry.register(Realtime.Registry, guild_id, nil)

    state = %{
      guild_id: guild_id,
      messages: 0
    }

    {:ok, state}
  end

  def handle_info({:event, event}, state) do
    new_state = handle_event(event, state)
    {:noreply, new_state}
  end

  defp handle_event(%{"type" => "MESSAGE_CREATE"}, state) do
    Realtime.Infrastructure.Redis.increment_messages(state.guild_id)

    %{state | messages: state.messages + 1}
  end

  defp handle_event(_, state), do: state
end
