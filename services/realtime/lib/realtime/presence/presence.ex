defmodule Realtime.Presence.Presence do
  use Phoenix.Presence,
    otp_app: :realtime,
    pubsub_server: Realtime.PubSub

  def init(_), do: {:ok, %{}}

  def handle_metas(
    topic,
    %{
      joins: joins,
      leaves: leaves
    },
    presences,
    state
  ) do
    handle_joins(topic, joins)
    handle_leaves(topic, leaves)

    {:ok, state}
  end

  defp handle_joins(_topic, joins) do
    Enum.each(joins, fn {user, _} ->
      Realtime.Presence.SessionTracker.user_joined(user)
    end)
  end

  defp handle_leaves(_topic, leaves) do
    Enum.each(leaves, fn {user, _} ->
      Realtime.Presence.SessionTracker.user_left(user)
    end)
  end
end
