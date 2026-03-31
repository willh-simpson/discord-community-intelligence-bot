defmodule Realtime.Distributed.ChannelProcess do
  use GenServer

  def init({guild_id, channel_id}) do
    {:ok, %{
      guild_id: guild_id,
      channel_id: channel_id,
      buckets: %{}
    }}
  end

  def start_link({guild_id, channel_id}) do
    GenServer.start_link(
      __MODULE__,
      {guild_id, channel_id},
      name: via(guild_id, channel_id)
    )
  end

  def handle_cast({:event, event}, state) do
    state = update_metrics(event, state)

    {:noreply, state}
  end

  defp update_metrics(%{
    "type" => "MESSAGE_CREATE"
  },
  state) do
    now = System.system_time(:second)
    bucket = div(now, 5)

    buckets = Map.update(state.buckets, bucket, 1, &(&1 + 1))

    %{state | buckets: buckets}
  end

  defp update_metrics(_, state), do: state
end
