defmodule Realtime.Ingestion.EventIngestor do
  use GenServer

  def init(state), do: {:ok, state}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def ingest(event) do
    GenServer.cast(__MODULE__, {:ingest, event})
  end

  def handle_cast({:ingest, event}, state) do
    track_presence(event)

    Realtime.Analytics.RateTracker.ingest(event)
    Realtime.Analytics.TopTracker.ingest(event)
    Realtime.Analytics.SpamTracker.ingest(event)
    Realtime.Analytics.AggregationTracker.ingest(event)
    Realtime.Analytics.ScoringPipeline.score_async(%{
      messages: [event],
      users: [event["user_id"]]
    })
    Realtime.Analytics.DjangoClient.ingest([
      %{
        user_id: event["user_id"],
        channel_id: event["channel_id"],
        content: event["content"],
        timestamp: DateTime.utc_now()
      }
    ])

    {:noreply, state}
  end

  defp track_presence(%{
    "type" => "MESSAGE_CREATE",
    "user_id" => user,
    "channel_id" => channel
  }) do
    topic = "channel:#{channel}"
    key = "#{user}"

    Realtime.Presence.Presence.track(
      self(),
      topic,
      key,
      %{
        user: user,
        channel: channel,
        last_seen: System.system_time(:second)
      }
    )
  end

  defp track_presence(_), do: :ok
end
