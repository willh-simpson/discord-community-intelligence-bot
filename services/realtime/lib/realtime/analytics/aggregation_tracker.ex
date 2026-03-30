defmodule Realtime.Analytics.AggregationTracker do
  use GenServer

  @bucket_seconds 5
  @retention_seconds 7 * 24 * 3_600 # only keep 7 days of data so large buckets of data aren't stored in memory
  @prune_interval_ms 60_000 # prune buckets periodically instead of after every single message

  def init(state) do
    :timer.send_interval(@prune_interval_ms, :prune)

    {:ok, state}
  end

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  # public api endpoints
  def ingest(event), do: GenServer.cast(__MODULE__, {:ingest, event})
  def metrics(window_seconds), do: GenServer.call(__MODULE__, {:metrics, window_seconds})
  def channels(), do: GenServer.call(__MODULE__, :channels)
  def message_rate(channel), do: GenServer.call(__MODULE__, {:rate, channel})

  def handle_info(:prune, state) do
    now = System.system_time(:second)
    min_bucket = div(now - @retention_seconds, @bucket_seconds)

    state =
      state
      |> Enum.map(fn {channel, buckets} ->
        buckets =
          buckets
          |> Enum.filter(fn {bucket, _} ->
            bucket >= min_bucket
          end)
          |> Enum.into(%{})

        {channel, buckets}
      end)
      |> Enum.into(%{})

    {:noreply, state}
  end

  def handle_cast(
    {:ingest,
      %{
        "type" => "MESSAGE_CREATE",
        "channel_id" => channel,

      }},
    state
  ) do
    now = System.system_time(:second)
    bucket = div(now, @bucket_seconds)

    channel_data = Map.get(state, channel, %{})
    messages = Map.get(channel_data, bucket, 0) + 1
    channel_data = Map.put(channel_data, bucket, messages)

    state = Map.put(state, channel, channel_data)

    {:noreply, state}
  end

  def handle_cast({:ingest, _}, state), do: {:noreply, state}

  # computes rolling metrics
  def handle_call({:metrics, window_seconds}, _from, state) do
    now = System.system_time(:second)
    min_bucket = div(now - window_seconds, @bucket_seconds)

    metrics =
      state
      |> Enum.map(fn {channel, buckets} ->
        count =
          buckets
          |> Enum.filter(fn {bucket, _} ->
            bucket >= min_bucket
          end)
          |> Enum.map(fn {_bucket, val} -> val end)
          |> Enum.sum()

        # get rate in messages/minute
        rate = count / (window_seconds / 60)

        {channel, Float.round(rate, 3)}
      end)
      |> Enum.into(%{})

    {:reply, metrics, state}
  end

  def handle_call(:channels, _from, state) do
    {:reply, Map.keys(state), state}
  end

  def handle_call({:rate, channel}, _from, state) do
    data = Map.get(state, channel, %{})
    buckets = Map.get(data, :buckets, %{})

    total = Enum.sum(Map.values(buckets))
    rate = total / max(map_size(buckets), 1)

    {:reply, rate, state}
  end

  # find spikes in channel activity where activity is 2x average
  def spikes(metrics) when map_size(metrics) == 0, do: %{}

  def spikes(metrics) do
    average =
      metrics
      |> Enum.map(fn {_channel, val} -> val end)
      |> Enum.sum()
      |> Kernel./(max(map_size(metrics), 1))

    metrics
    |> Enum.filter(fn {_channel, val} ->
      val > 2 * average
    end)
    |> Enum.into(%{}, fn {channel, val} ->
      {channel, %{
        rate: val,
        average: average,
        multiplier:
          if average == 0 do
            0
          else
            val / average
          end
      }}
    end)
  end

  def parse_window(nil), do: 86_400 # default window is 24 hours

  def parse_window(str) do
    case Regex.run(~r/^(\d+)(y|mo|w|d|h|m|s)$/, str) do
      [_, num, unit] ->
        n = String.to_integer(num)

        case unit do
          "s" -> n                # seconds
          "m" -> n * 60           # minutes
          "h" -> n * 3_600        # hours
          "d" -> n * 86_400       # days
          "w" -> n * 604_800      # weeks
          "mo" -> n * 2_628_000   # months
          "y" -> n * 31_536_000   # years
        end

      _ ->
        86_400
    end
  end
end
