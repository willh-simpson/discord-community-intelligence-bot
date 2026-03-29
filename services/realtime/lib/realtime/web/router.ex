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

    timeout_seconds = 300 # stop tracking users after 5 minutes of inactivity
    now = System.system_time(:second)

    # active_count =
    #   Realtime.Presence.Presence.list(topic)
    #   |> Enum.filter(fn {_user, meta} ->
    #     last_seen Map.get(meta, :last_seen, 0)
    #     now - last_seen <= timeout_seconds
    #   end)
    #   |> Enum.count()
    active_count =
      Enum.each(
        Realtime.Presence.Presence.list(topic),
        fn {user, meta} ->
          if now - Map.get(meta, :last_seen, 0) > timeout_seconds do
            Realtime.Presence.Presence.untrack(self(), topic, user)
          end
        end
      )

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

  match _ do
    send_resp(conn, 404, "not found")
  end
end
