defmodule Realtime.Distributed.GuildProcess do
  use GenServer

  def start_link(guild_id) do
    GenServer.start_link(__MODULE__, guild_id, name: via(guild_id))
  end

  def init(guild_id) do
    {:ok, _} = DynamicSupervisor.start_link(
      strategy: :one_for_one,
      name: channel_supervisor(guild_id)
    )

    {:ok, %{guild_id: guild_id}}
  end

  def channel_supervisor(guild_id), do: {:via, Registry, {Realtime.ChannelSupervisorRegistry, guild_id}}

  def handle_info({:event, event}, state) do
    new_state = handle_event(event, state)
    {:noreply, new_state}
  end

  defp handle_event(%{"type" => "MESSAGE_CREATE"}, state) do
    Realtime.Infrastructure.Redis.increment_messages(state.guild_id)

    %{state | messages: state.messages + 1}
  end

  defp handle_event(_, state), do: state

  defp via(guild_id) do
    {:via, Registry, {Realtime.GuildRegistry, guild_id}}
  end
end
