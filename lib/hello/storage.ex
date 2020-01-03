defmodule Hello.Storage do
  use GenServer

  @update_interval 24*60*60*1000
  @fallback_interval 60*1000

  def start_link(_params) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def put(store) do
    GenServer.cast(__MODULE__, {:put, store})
  end

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def get(stars) do
    GenServer.call(__MODULE__, {:get, stars})
  end

  @impl true
  def init(_) do
    Hello.Loader.subscribe(__MODULE__)
    Hello.Loader.reload()
    Process.send_after(__MODULE__, :reload, @update_interval)
    Process.send_after(__MODULE__, :fallback, @fallback_interval)
    {:ok, []}
  end

  @impl true
  def handle_info(:reload, state) do
    Hello.Loader.reload()
    Process.send_after(__MODULE__, :reload, @update_interval)
    {:noreply, state}
  end

  @impl true
  def handle_info(:fallback, state) do
    Hello.Loader.fallback()
    Process.send_after(__MODULE__, :fallback, @fallback_interval)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:put, store}, _state) do
      broadcast()
      {:noreply, store}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get, min_stars}, _from, state) do
    {min_stars, _} = Integer.parse(min_stars)
    filter_fn = fn
      {_, %{stars: stars}} -> stars >= min_stars
    end

    {:reply, Enum.filter(state, filter_fn), state}
  end

  defp broadcast() do
    HelloWeb.Endpoint.broadcast("github:update", "outdated", %{})
  end
end
