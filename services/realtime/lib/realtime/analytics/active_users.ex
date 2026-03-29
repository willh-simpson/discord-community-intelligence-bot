defmodule Realtime.Analytics.ActiveUsers do
  def count(guild) do
    topic = "guilde:#{guild}"

    Realtime.Presence.Presence.list(topic)
    |> map_size()
  end
end
