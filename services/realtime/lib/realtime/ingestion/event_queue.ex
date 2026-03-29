defmodule Realtime.Ingestion.EventQueue do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :queue.new(), name: __MODULE__)
  end

  def enqueue(event) do
    GenServer.cast(__MODULE__, {:enqueue, event})
  end

  def init(queue) do
    {:ok, queue}
  end

  def handle_cast({:enqueue, event}, queue) do
    new_queue = :queue.in(event, queue)
    process_queue(new_queue)
  end

  defp process_queue(queue) do
    case :queue.out(queue) do
      {{:value, event}, rest} ->
        Realtime.Guilds.GuildRouter.route(event)
        {:noreply, rest}

      {:empty, queue} ->
        {:noreply, queue}
    end
  end
end
