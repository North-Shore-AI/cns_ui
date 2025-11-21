defmodule CnsUiWeb.Components.EntailmentMeter do
  @moduledoc """
  Component for displaying entailment verification scores.
  """

  use Phoenix.Component

  @doc """
  Renders an entailment meter component.

  ## Examples

      <.entailment_meter value={0.95} />
      <.entailment_meter value={0.75} target={0.90} show_target={true} />
  """
  attr :value, :float, required: true, doc: "Entailment score between 0.0 and 1.0"
  attr :target, :float, default: 0.95
  attr :show_target, :boolean, default: true
  attr :label, :string, default: "Entailment Score"

  def entailment_meter(assigns) do
    percentage = assigns.value * 100
    on_target = assigns.value >= assigns.target

    assigns =
      assigns
      |> assign(:percentage, percentage)
      |> assign(:on_target, on_target)
      |> assign(:bar_color, if(on_target, do: "bg-green-500", else: "bg-yellow-500"))

    ~H"""
    <div class="space-y-2">
      <div class="flex justify-between items-center">
        <span class="text-sm font-medium text-gray-700"><%= @label %></span>
        <span class={"text-sm font-bold #{if @on_target, do: "text-green-600", else: "text-yellow-600"}"}>
          <%= Float.round(@percentage, 1) %>%
        </span>
      </div>

      <div class="relative h-4 bg-gray-200 rounded-full overflow-hidden">
        <div
          class={"h-full #{@bar_color} transition-all duration-300"}
          style={"width: #{@percentage}%"}
        >
        </div>
        <%= if @show_target do %>
          <div
            class="absolute top-0 bottom-0 w-0.5 bg-red-500"
            style={"left: #{@target * 100}%"}
            title={"Target: #{@target * 100}%"}
          >
          </div>
        <% end %>
      </div>

      <%= if @show_target do %>
        <p class="text-xs text-gray-500">
          Target: <%= Float.round(@target * 100, 1) %>%
          <%= if @on_target do %>
            <span class="text-green-600">(achieved)</span>
          <% else %>
            <span class="text-yellow-600">
              (<%= Float.round((@target - @value) * 100, 1) %>% to go)
            </span>
          <% end %>
        </p>
      <% end %>
    </div>
    """
  end
end
