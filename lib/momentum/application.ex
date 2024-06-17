defmodule Momentum.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MomentumWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:momentum, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Momentum.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Momentum.Finch},
      # Start a worker by calling: Momentum.Worker.start_link(arg)
      # {Momentum.Worker, arg},
      # Start to serve requests, typically the last entry
      MomentumWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Momentum.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MomentumWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
