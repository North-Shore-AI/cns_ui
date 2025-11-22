defmodule CnsUi.CNS.HTTPAdapter do
  @moduledoc """
  HTTP adapter for CNS overlay endpoints. Keeps LiveViews insulated from Tinkex specifics.
  """
  @behaviour CnsUi.CNS.Adapter
  alias CnsUi.Clients.HTTP

  @impl true
  def list_overlays(opts \\ []) do
    with {:ok, base_url} <- fetch_base_url(opts),
         {:ok, %{"data" => overlays}} <- HTTP.get("#{base_url}/overlays", opts) do
      {:ok, Enum.map(overlays, &normalize_overlay/1)}
    else
      {:ok, decoded} -> {:ok, normalize_overlays(decoded)}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def list_routes(opts \\ []) do
    with {:ok, base_url} <- fetch_base_url(opts),
         {:ok, %{"data" => routes}} <- HTTP.get("#{base_url}/routes", opts) do
      {:ok, Enum.map(routes, &normalize_route/1)}
    else
      {:ok, decoded} -> {:ok, normalize_routes(decoded)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_base_url(opts) do
    base_url = Keyword.get(opts, :base_url) || System.get_env("CNS_BASE_URL")

    case base_url do
      nil -> {:error, :missing_base_url}
      url -> {:ok, String.trim_trailing(url, "/")}
    end
  end

  defp normalize_overlays(%{"data" => data}) when is_list(data), do: normalize_overlays(data)
  defp normalize_overlays(data) when is_list(data), do: Enum.map(data, &normalize_overlay/1)
  defp normalize_overlays(_), do: {:error, :unexpected_payload}

  defp normalize_routes(%{"data" => data}) when is_list(data), do: normalize_routes(data)
  defp normalize_routes(data) when is_list(data), do: Enum.map(data, &normalize_route/1)
  defp normalize_routes(_), do: {:error, :unexpected_payload}

  defp normalize_overlay(%{"id" => id, "region" => region} = overlay) do
    %{
      id: id,
      region: region,
      status: Map.get(overlay, "status", "unknown"),
      namespace: Map.get(overlay, "namespace"),
      active_sessions: Map.get(overlay, "active_sessions"),
      capacity: Map.get(overlay, "capacity")
    }
  end

  defp normalize_overlay(%{id: id, region: region} = overlay) do
    %{
      id: id,
      region: region,
      status: Map.get(overlay, :status, "unknown"),
      namespace: Map.get(overlay, :namespace),
      active_sessions: Map.get(overlay, :active_sessions),
      capacity: Map.get(overlay, :capacity)
    }
  end

  defp normalize_overlay(other), do: other

  defp normalize_route(%{"source" => source, "target" => target} = route) do
    %{
      source: source,
      target: target,
      status: Map.get(route, "status", "unknown"),
      latency_ms: Map.get(route, "latency_ms"),
      error_rate: Map.get(route, "error_rate")
    }
  end

  defp normalize_route(%{source: source, target: target} = route) do
    %{
      source: source,
      target: target,
      status: Map.get(route, :status, "unknown"),
      latency_ms: Map.get(route, :latency_ms),
      error_rate: Map.get(route, :error_rate)
    }
  end

  defp normalize_route(other), do: other
end
