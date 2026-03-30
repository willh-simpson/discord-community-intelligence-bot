defmodule Realtime.Moderation.SafetySignals do
  use GenServer

  @bucket_seconds 5
  @retention_seconds 24 * 3_600 # track 24 hours of data at a time
  @alert_threshold 5

  def init(state) do
    :timer.send_interval(60_000, :prune) # prune old buckets per minute to free memory

    {:ok, state}
  end

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def ingest(event), do: GenServer.cast(__MODULE__, {:ingest, event})
  def alerts(), do: GenServer.call(__MODULE__, :alerts)
  def mod_risk(channel_id), do: GenServer.call(__MODULE__, {:mod_risk, channel_id})

  def handle_info(:prune, state) do
    now = System.system_time(:second)
    cutoff = now - @retention_seconds

    pruned = Enum.map(state, fn {key, data} ->
      buckets = Map.get(data, :buckets, %{})

      filtered = Enum.filter(buckets, fn {bucket, _count} ->
        bucket_time = bucket * @bucket_seconds
        bucket_time >= cutoff
      end)
      |> Enum.into(%{})

      {key, Map.put(data, :buckets, filtered)}
    end)
    |> Enum.into(%{})

    {:noreply, pruned}
  end

  def handle_cast(
    {:ingest,
    %{
      "type" => "MESSAGE_CREATE",
      "channel_id" => channel
    }},
    state
  ) do
    now = System.system_time(:second)
    bucket = div(now, @bucket_seconds)

    channel_state = Map.get(state, channel, %{
      buckets: %{},
      alerts: []
    })

    buckets = channel_state.buckets
    count = Map.get(buckets, bucket, 0) + 1
    buckets = Map.put(buckets, bucket, count)

    updated_state = %{channel_state | buckets: buckets}

    alerts = detect_alerts(channel, updated_state) ++ detect_burst(channel, buckets)
    send_alerts(alerts)

    state = Map.put(state, channel, %{
      buckets: buckets,
      alerts: alerts
    })

    {:noreply, state}
  end

  # suspicious joins/raid detection
  def handle_cast(
    {:ingest,
    %{
      "type" => "GUILD_MEMBER_ADD",
      "guild_id" => guild,
      "user_id" => user
    } = event},
    state
  ) do
    now = System.system_time(:second)

    guild_data = Map.get(state, guild, %{})
    joins = Map.get(guild_data, :joins, [])
    guild_data = Map.put(guild_data, :joins, [{user, now} | joins])

    alerts = if length(joins) > 10 do
      [%{type: :raid, guild: guild, count: length(joins)}]
    else
      []
    end
    send_alerts(alerts)

    state = Map.put(state, guild, guild_data |> Map.put(:alerts, alerts))

    {:noreply, state}
  end

  # computes score risk for a given channel
  def handle_call({:mod_risk, channel}, _from, state) do
    channel_data = Map.get(state, channel, %{buckets: %{}, alerts: []})
    score =
      channel_data.alerts
      |> Enum.map(fn alert ->
        case alert.type do
          :spam -> 5
          :burst -> 3
          _ -> 1
        end
      end)
      |> Enum.sum()

    {:reply, score, state}
  end

  # stores spam, message bursts, suspicious joins, raids, etc.
  defp detect_alerts(channel, channel_data) do
    buckets = Map.get(channel_data, :buckets, %{})
    recent_counts = Map.values(buckets)
    total_recent = Enum.sum(recent_counts)

    cond do
      total_recent > @alert_threshold ->
        [%{type: :spam, channel: channel, count: total_recent}]

      true ->
        []
    end
  end

  # detects sudden large spikes relative to previous activity
  defp detect_burst(channel, buckets) do
    if map_size(buckets) == 0 do
      []
    else
      values = Map.values(buckets)
      average = Enum.sum(values) / length(values)

      current =
        buckets
        |> Map.values()
        |> List.last()

      # trending channels are 2x above average and are not necessarily spam indicators.
      # a particularly large spike might be an indicator of spam.
      if current > 3.5 * average do
        [%{type: :burst, channel: channel, count: current}]
      else
        []
      end
    end
  end

  defp send_alerts(alerts) do
    Enum.each(alerts, fn alert ->
      Realtime.Web.DjangoClient.post_safety_alert(%{
        type: alert.type,
        channel: Map.get(alert, :channel),
        guild: Map.get(alert, :guild),
        count: alert.count
      })
    end)
  end
end
