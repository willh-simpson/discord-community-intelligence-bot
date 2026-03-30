defmodule Realtime.Web.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  post "/ingest" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    event = Jason.decode!(body)

    Realtime.Ingestion.EventIngestor.ingest(event)

    send_resp(conn, 200, "ok")
  end

  get "/health" do
    send_resp(conn, 200, "ok")
  end

  #
  # active users
  #
  get "/active/:channel_id" do
    topic = "channel:#{channel_id}"

    timeout_seconds = 300
    now = System.system_time(:second)

    presences = Realtime.Presence.Presence.list(topic)

    # remove expired users to free memory
    Enum.each(presences, fn {user, meta} ->
      last_seen = Map.get(meta, :last_seen, 0)

      if now - last_seen > timeout_seconds do
        Realtime.Presence.Presence.untrack(self(), topic, user)
      end
    end)

    active_count =
      Realtime.Presence.Presence.list(topic)
      |> Enum.reduce(0, fn {user, %{metas: metas}}, acc ->
        last_seen =
        case metas do
          [meta | _] -> Map.get(meta, :last_seen, 0)
          _ -> 0
        end

      if now - last_seen <= timeout_seconds do
        acc + 1
      else
        Realtime.Presence.Presence.untrack(self(), topic, user)
        acc
      end
    end)

    body =
      Jason.encode!(%{
        active_users: active_count
      })

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  #
  # user sessions
  #
  get "/sessions/:channel_id" do
    topic = "channel:#{channel_id}"

    sessions =
      topic
      |> Realtime.Presence.Presence.list()
      |> Enum.map(fn {user, %{metas: metas}} ->
        %{
          user: user,
          sessions: metas
        }
      end)

    body = Jason.encode!(sessions)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  #
  # top users
  #
  get "/top" do
    top_users = Realtime.Analytics.TopTracker.top()

    body = Jason.encode!(%{
      top: top_users
    })

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  #
  # message rate per user
  #
  get "/rate/:user_id" do
    rate = Realtime.Analytics.RateTracker.rate(user_id)

    body = Jason.encode!(%{
      rate: rate
    })

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  #
  # spam detection
  #
  get "/spam" do
    spammers = Realtime.Analytics.SpamTracker.spammers()

    body = Jason.encode!(%{
      spammers: spammers
    })

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  #
  # channel activity per channel + activity spikes
  #
  get "/activity" do
    conn = Plug.Conn.fetch_query_params(conn)

    window =
      conn.params["window"]
      |> Realtime.Analytics.AggregationTracker.parse_window()

    metrics = Realtime.Analytics.AggregationTracker.metrics(window)
    spikes = Realtime.Analytics.AggregationTracker.spikes(metrics)

    body = Jason.encode!(%{
      window_seconds: window,
      activity: metrics,
      spikes: spikes
    })

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  #
  # sorts activity spikes per channel with activity spikes
  #
  get "/trending" do
    conn = Plug.Conn.fetch_query_params(conn)

    window =
      conn.params["window"]
      |> Realtime.Analytics.AggregationTracker.parse_window()

    metrics = Realtime.Analytics.AggregationTracker.metrics(window)

    trending =
      metrics
      |> Realtime.Analytics.AggregationTracker.spikes()
      |> Enum.sort_by(fn {_channel, count} -> -count end)
      |> Enum.into(%{})

    body = Jason.encode!(%{
      window_seconds: window,
      trending: trending
    })

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  #
  # server activity insights
  #
  get "/insights" do
    data = Realtime.Analytics.AnalyticsWorker.get()

    body = Jason.encode!(data)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
