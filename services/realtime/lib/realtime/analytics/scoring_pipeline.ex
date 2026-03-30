defmodule Realtime.Analytics.ScoringPipeline do
  alias Realtime.Web.DjangoClient

  def score_async(payload) do
    Task.start(fn ->
      with  {:ok, %{status_code: 200, body: body}} <-
              DjangoClient.extract_features(payload),
            {:ok, decoded} <- Jason.decode(body),
            {:ok, %{status_code: 200, body: score_body}} <-
              DjangoClient.engagement_score(decoded) do
                Jason.decode!(score_body)
              else
                _ -> :error
              end
    end)
  end
end
