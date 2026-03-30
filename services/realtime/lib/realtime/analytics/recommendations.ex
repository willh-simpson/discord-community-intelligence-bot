defmodule Realtime.Analytics.Recommendations do

  def score_channel(channel_stats) do
    rate_weight = 0.5
    core_member_weight = 0.3
    burst_weight = 0.2

    rate = Map.get(channel_stats, :message_rate, 0)
    core = Map.get(channel_stats, :core_members, 0)
    burst = Map.get(channel_stats, :bursts)

    (rate * rate_weight) + (core * core_member_weight) + (burst * burst_weight)
  end

  def recommend(channels_stats) do
    channels_stats
    |> Enum.map(fn {channel, stats} ->
      {channel, score_channel(stats)}
    end)
    |> Enum.sort_by(fn {_channel, score} -> -score end)
  end
end
