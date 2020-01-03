defmodule HelloWeb.GithubChannel do
  use Phoenix.Channel
  def join("github:update", _msg, socket) do
    {:ok, socket}
  end

  def handle_in("get_status", %{"stars" => stars}, socket) do
    response = Hello.Storage.get(stars) |> Hello.Parser.modify_result()
    push socket, "new_status", %{response: response}
    {:noreply, socket}
  end

  def handle_in("get_status", _, socket) do
    response =  Hello.Storage.get() |> Hello.Parser.modify_result()
    push socket, "new_status", %{response: response}
    {:noreply, socket}
  end
end
