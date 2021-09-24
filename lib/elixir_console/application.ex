defmodule ElixirConsole.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: ElixirConsole.PubSub},
      # Start the Endpoint (http/https)
      ElixirConsoleWeb.Endpoint,
      ElixirConsoleWeb.LiveMonitor,
      ElixirConsole.Documentation
      # Start a worker by calling: ElixirConsole.Worker.start_link(arg)
      # {ElixirConsole.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirConsole.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ElixirConsoleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
