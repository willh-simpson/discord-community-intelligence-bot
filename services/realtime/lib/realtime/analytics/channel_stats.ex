defmodule Realtime.Analytics.ChannelStats do
  use GenServer

  def init(state), do: {:ok, state}

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def get_all(), do: GenServer.call(__MODULE__, :stats)

  def handle_call(:stats, _from, state) do
    channels = Realtime.Analytics.AggregationTracker.channels()

    stats = Enum.map(channels, fn channel ->
      rate =
        Realtime.Analytics.AggregationTracker.message_rate(channel)

      forecast =
        Realtime.Analytics.Forecaster.forecast(channel)

      bursts =
        if rate == 0 do
          0
        else
          forecast / rate
        end

      decline_rate = rate - forecast

      {channel, %{
        message_rate: rate,
        forecast: forecast,
        bursts: bursts,
        decline_rate: decline_rate
      }}
    end)

    {:reply, stats, state}
  end
end
