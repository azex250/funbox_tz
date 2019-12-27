defmodule HelloWeb.HelloController do
  use HelloWeb, :controller

  def world(conn, %{"name" => name}) do
    conn
    |> put_flash(:info, "Welcome to Phoenix, from flash info!")
    |> put_flash(:error, "Let's pretend we have an error.")
    |> render("world.html", name: name)
  end
end
