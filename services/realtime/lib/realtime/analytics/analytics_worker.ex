defmodule Realtime.Analytics.AnalyticsWorker do
  use GenServer

  alias Realtime.Analytics.DjangoClient

  @refresh_interval :timer.seconds(10)

  @impl true
  def init(_) do
    schedule_refresh()

    {:ok, %{insights: %{}, last_updated: nil}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get() do
      GenServer.call(__MODULE__, :get)
    end

  def refresh() do
    GenServer.cast(__MODULE__, :refresh)
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:refresh, state) do
    new_state = fetch_insights(state)

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:refresh, state) do
    schedule_refresh()
    new_state = fetch_insights(state)

    {:noreply, new_state}
  end

  defp schedule_refresh() do
    Process.send_after(self(), :refresh, @refresh_interval)
  end

  defp fetch_insights(state) do
    case DjangoClient.insights() do
      {:ok, %{status_code: 200, body: body}} ->
        insights = Jason.decode!(body)

        %{
          state
          | insights: insights,
            last_updated: System.system_time(:second)
        }

      _ ->
        state
    end
  end
end
