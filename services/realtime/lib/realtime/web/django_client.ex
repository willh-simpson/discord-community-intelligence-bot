defmodule Realtime.Web.DjangoClient do
  @base_url "http://analytics:8000/api"

  def health() do
    case HTTPoison.get("#{@base_url}/health/") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  def ingest(events) do
    HTTPoison.post(
      "#{@base_url}/ingest/",
      Jason.encode!(%{events: events}),
      [{"Content-Type", "application/json"}]
    )
  end

  def insights() do
    HTTPoison.get("#{@base_url}/insights/")
  end

  def extract_features(payload) do
    HTTPoison.post(
      "#{@base_url}/extract-features/",
      Jason.encode!(payload),
      [{
        "Content-Type", "application/json"
      }]
    )
  end

  def engagement_score(payload) do
    HTTPoison.post(
      "#{@base_url}/score/",
      Jason.encode!(payload),
      [{
        "Content-Type", "application/json"
      }]
    )
  end

  def post_safety_alert(alert) do
    HTTPoison.post(
      "#{@base_url}/safety-alert/",
      Jason.encode!(alert),
      [{"Content-Type", "application/json"}]
    )
  end

  def post_forecast(channel, forecast) do
    HTTPoison.post(
      "#{@base_url}/forecast/",
      Jason.encode!(%{
        channel: channel,
        forecast: forecast
      }),
      [{"Content-Type", "application/json"}]
    )
  end
end
