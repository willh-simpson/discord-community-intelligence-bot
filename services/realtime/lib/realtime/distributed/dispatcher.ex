defmodule Realtime.Distributed.Dispatcher do
  def dispatch(%{
    "guild_id" => guild,
    "channel_id" => channel
  } = event) do
    ensure_guild(guild)
    ensure_channel(guild, channel)

    GenServer.cast(via_channel(guild, channel), {:event, event})
  end

  defp ensure_guild(guild) do
    case Registry.lookup(Realtime.GuildRegistry, guild) do
      [] ->
        Realtime.Distributed.GuildSupervisor.start_guild(guild)

      _ ->
        :ok
    end
  end

  defp ensure_channel(guild, channel) do
    case Registry.lookup(Realtime.ChannelRegistry, {guild, channel}) do
      [] ->
        start_channel(guild, channel)

      _ ->
        :ok
    end
  end

  defp start_channel(guild, channel) do
    supervisor = Realtime.Distributed.GuildProcess.channel_supervisor(guild)
    spec = {Realtime.Distributed.ChannelProcess, {guild, channel}}

    DynamicSupervisor.start_child(supervisor, spec)
  end

  defp via_channel(guild, channel), do: {:via, Registry, {Realtime.ChannelRegistry, {guild, channel}}}
end
