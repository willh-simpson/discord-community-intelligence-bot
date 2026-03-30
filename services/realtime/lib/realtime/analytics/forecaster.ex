defmodule Realtime.Analytics.Forecaster do
  use GenServer

  @bucket_seconds 5
  @forecast_horizon 5 # 5 minute horizon

  def init(state), do: {:ok, state}

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def forecast(channel), do: GenServer.call(__MODULE__, {:forecast, channel})

  def handle_call({:forecast, channel}, _from, state) do
    data = Map.get(state, channel, [])
    prediction = simple_forecast(data)

    {:reply, prediction, state}
  end

  # rolling average forecast
  defp simple_forecast(data) do
    average_bucket = Enum.sum(data) / max(length(data), 1)
    average_per_minute = average_bucket * (60 / @bucket_seconds)

    average_per_minute * @forecast_horizon
  end
end
