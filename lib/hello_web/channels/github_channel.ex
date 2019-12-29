defmodule HelloWeb.GithubChannel do
  use Phoenix.Channel
  def join("github:update", _msg, socket) do
    {:ok, socket}
  end

  def handle_in("get_status", %{"stars" => stars}, socket) do
    push socket, "new_status", %{response: Hello.ElixirServer.state(stars)}
    {:noreply, socket}
  end

  def handle_in("get_status", _, socket) do
    push socket, "new_status", %{response: Hello.ElixirServer.state()}
    {:noreply, socket}
  end
end
