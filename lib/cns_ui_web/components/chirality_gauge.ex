defmodule CnsUiWeb.Components.ChiralityGauge do
  @moduledoc """
  Component for displaying chirality scores as a gauge visualization.
  """

  use Phoenix.Component

  @doc """
  Renders a chirality gauge component.

  ## Examples

      <.chirality_gauge value={0.5} />
      <.chirality_gauge value={-0.3} label="Left-handed" />
  """
  attr :value, :float, required: true, doc: "Chirality value between -1.0 and 1.0"
  attr :label, :string, default: nil
  attr :size, :string, default: "md", values: ["sm", "md", "lg"]

  def chirality_gauge(assigns) do
    # Normalize value from -1..1 to 0..100 for display
    normalized = (assigns.value + 1) / 2 * 100

    sizes = %{
      "sm" => "h-24 w-24",
      "md" => "h-32 w-32",
      "lg" => "h-48 w-48"
    }

    assigns =
      assigns
      |> assign(:normalized, normalized)
      |> assign(:size_class, Map.get(sizes, assigns.size, "h-32 w-32"))
      |> assign(:chirality_label, chirality_label(assigns.value))

    ~H"""
    <div class="flex flex-col items-center">
      <div class={"relative #{@size_class}"}>
        <svg viewBox="0 0 100 100" class="transform -rotate-90">
          <%!-- Background arc --%>
          <circle cx="50" cy="50" r="40" fill="none" stroke="#e5e7eb" stroke-width="10" />
          <%!-- Value arc --%>
          <circle
            cx="50"
            cy="50"
            r="40"
            fill="none"
            stroke={gauge_color(@value)}
            stroke-width="10"
            stroke-dasharray={"#{@normalized * 2.51} 251"}
            stroke-linecap="round"
          />
        </svg>
        <div class="absolute inset-0 flex items-center justify-center">
          <span class="text-lg font-bold"><%= Float.round(@value, 2) %></span>
        </div>
      </div>
      <p class="mt-2 text-sm text-gray-600">
        <%= @label || @chirality_label %>
      </p>
    </div>
    """
  end

  defp gauge_color(value) when value < -0.5, do: "#ef4444"
  defp gauge_color(value) when value < 0, do: "#f97316"
  defp gauge_color(value) when value < 0.5, do: "#eab308"
  defp gauge_color(_value), do: "#22c55e"

  defp chirality_label(value) when value < -0.5, do: "Strong Left"
  defp chirality_label(value) when value < 0, do: "Left-leaning"
  defp chirality_label(value) when value == 0, do: "Balanced"
  defp chirality_label(value) when value < 0.5, do: "Right-leaning"
  defp chirality_label(_value), do: "Strong Right"
end
