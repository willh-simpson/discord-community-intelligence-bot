defmodule Realtime.Guilds.GuildRouter do
  def route(event) do
    guild_id = event["guild_id"]

    pid = Realtime.Guilds.GuildSupervisor.get_guild(guild_id)

    send(pid, {:event, event})
  end
end
