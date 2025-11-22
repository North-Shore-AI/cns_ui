defmodule CnsUi.CNS.Adapter do
  @moduledoc """
  Behaviour describing the CNS overlay client surface area.
  """

  @typedoc "Overlay metadata returned by adapters."
  @type overlay ::
          %{
            required(:id) => String.t(),
            required(:region) => String.t(),
            required(:status) => String.t(),
            optional(:namespace) => String.t(),
            optional(:active_sessions) => integer(),
            optional(:capacity) => integer(),
            optional(:updated_at) => DateTime.t() | nil
          }

  @typedoc "Route metadata connecting CNS overlay segments."
  @type route ::
          %{
            required(:source) => String.t(),
            required(:target) => String.t(),
            required(:status) => String.t(),
            optional(:latency_ms) => integer(),
            optional(:error_rate) => float()
          }

  @callback list_overlays(keyword()) :: {:ok, [overlay()]} | {:error, term()}
  @callback list_routes(keyword()) :: {:ok, [route()]} | {:error, term()}
end
