defmodule Realtime.Distributed.GuildSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # def get_guild(guild_id) do
  #   case Registry.lookup(Realtime.Registry, guild_id) do
  #     [{pid, _}] ->
  #       pid

  #     [] ->
  #       {:ok, pid} =
  #         DynamicSupervisor.start_child(__MODULE__, {Realtime.Distributed.GuildProcess, guild_id})

  #       pid
  #   end
  # end

  def start_guild(guild_id) do
    spec = {Realtime.Distributed.GuildProcess, guild_id}
    DynamicSupervisor.start_child(__MODULE, spec)
  end
end
