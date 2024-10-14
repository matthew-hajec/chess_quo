defmodule EasyChess.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EasyChessWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:easy_chess, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EasyChess.PubSub},
      {Redix,
       [
         name: :redix,
         host: Application.get_env(:redix, :redis_host),
         port: Application.get_env(:redix, :redis_port),
         password: Application.get_env(:redix, :redis_password)
       ]},
      # Start to serve requests, typically the last entry
      EasyChessWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EasyChess.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EasyChessWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
