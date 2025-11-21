defmodule CnsUi.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CnsUiWeb.Telemetry,
      CnsUi.Repo,
      {DNSCluster, query: Application.get_env(:cns_ui, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CnsUi.PubSub},
      {Finch, name: CnsUi.Finch},
      CnsUiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: CnsUi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CnsUiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
