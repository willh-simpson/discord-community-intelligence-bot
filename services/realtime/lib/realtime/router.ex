defmodule Realtime.Router do
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

    Realtime.EventIngestor.ingest(event)

    send_resp(conn, 200, "ok")
  end

  get "/health" do
    send_resp(conn, 200, "ok")
  end

  get "/active/:channel_id" do
    count = Realtime.PresenceTracker.active_users(channel_id)

    body =
      Jason.encode!(%{
        active_users: count
      })

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  get "/sessions/:channel_id" do
    sessions = Realtime.PresenceTracker.sessions(channel_id)

    body = Jason.encode!(sessions)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  get "/top" do
    top_users = Realtime.TopTracker.top()

    body = Jason.encode!(%{top: top_users})

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  get "/rate/:user_id" do
    rate = Realtime.RateTracker.rate(user_id)

    body = Jaosn.encode!(%{rate: rate})

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  get "/spam" do
    spammers = Realtime.SpamTracker.spammers()

    body = Jason.encode!(%{spammers: spammers})

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
