defmodule Hello.SocketServer do
  use GenServer

  @update_interval 60*60*1000
  @fallback_interval 60*1000

  def start_link(_params) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Hello.ElixirServer.reload |> broadcast
    Process.send_after(self(), :reload, @update_interval)
    Process.send_after(self(), :fallback, @fallback_interval)
    {:ok, []}
  end

  @impl true
  def handle_info(:reload, state) do
    Hello.ElixirServer.reload|> broadcast
    Process.send_after(self(), :reload, @update_interval)
    {:noreply, state}
  end

  @impl true
  def handle_info(:fallback, state) do
    Hello.ElixirServer.fallback |> broadcast
    Process.send_after(self(), :fallback, @fallback_interval)
    {:noreply, state}
  end

  defp broadcast({:ok, _store}) do
    HelloWeb.Endpoint.broadcast("github:update", "outdated", %{})
  end
end
