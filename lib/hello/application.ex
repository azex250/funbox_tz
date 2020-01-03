defmodule Hello.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    # List all child processes to be supervised
    children = [
      HelloWeb.Endpoint,
    ] ++ services()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HelloWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp services() do
    case Application.get_env(:hello, :children)[:enable] do
      true -> [
        Application.get_env(:hello, :children)[:loader],
        Application.get_env(:hello, :children)[:storage]
      ]
      false -> []
    end
  end
end
