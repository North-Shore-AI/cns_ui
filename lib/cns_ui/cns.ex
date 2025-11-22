defmodule CnsUi.CNS do
  @moduledoc """
  Facade for CNS overlay operations routed through a configurable adapter.
  """
  alias CnsUi.CNS.Adapter

  @type overlay :: Adapter.overlay()
  @type route :: Adapter.route()

  @spec list_overlays(keyword()) :: {:ok, [overlay()]} | {:error, term()}
  def list_overlays(opts \\ []), do: adapter().list_overlays(with_env_opts(opts))

  @spec list_routes(keyword()) :: {:ok, [route()]} | {:error, term()}
  def list_routes(opts \\ []), do: adapter().list_routes(with_env_opts(opts))

  defp adapter do
    client_config()
    |> Keyword.get(:adapter, CnsUi.CNS.StubAdapter)
  end

  defp with_env_opts(opts) do
    Keyword.merge(client_config(), opts)
  end

  defp client_config do
    Application.get_env(:cns_ui, :cns_client, [])
  end
end
