defmodule CnsUi.CNS.StubAdapter do
  @moduledoc """
  Stub CNS adapter used for local development and testing without hitting Tinkex directly.
  """
  @behaviour CnsUi.CNS.Adapter

  @impl true
  def list_overlays(opts \\ []) do
    namespace = Keyword.get(opts, :namespace, "local")

    overlays = [
      %{
        id: "cns-east-1",
        region: "iad",
        status: "healthy",
        namespace: namespace,
        active_sessions: 18,
        capacity: 32
      },
      %{
        id: "cns-west-2",
        region: "sfo",
        status: "degraded",
        namespace: namespace,
        active_sessions: 11,
        capacity: 24
      },
      %{
        id: "cns-eu-1",
        region: "fra",
        status: "pending",
        namespace: namespace,
        active_sessions: 6,
        capacity: 20
      }
    ]

    {:ok, overlays}
  end

  @impl true
  def list_routes(opts \\ []) do
    namespace = Keyword.get(opts, :namespace, "local")

    routes = [
      %{source: "iad", target: "sfo", status: "healthy", latency_ms: 46, error_rate: 0.003},
      %{source: "iad", target: "fra", status: "degraded", latency_ms: 89, error_rate: 0.012},
      %{source: "fra", target: "sfo", status: "pending", latency_ms: 120, error_rate: 0.0}
    ]

    routes
    |> Enum.map(&Map.put(&1, :namespace, namespace))
    |> then(&{:ok, &1})
  end
end
