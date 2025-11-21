defmodule CnsUiWeb.Components.TopologyGraph do
  @moduledoc """
  Component for displaying topology/Betti number visualizations.
  """

  use Phoenix.Component

  @doc """
  Renders a topology graph placeholder component.

  ## Examples

      <.topology_graph nodes={snos} />
  """
  attr :nodes, :list, default: []
  attr :layout, :string, default: "force", values: ["force", "hierarchical", "radial"]
  attr :height, :string, default: "400px"

  def topology_graph(assigns) do
    ~H"""
    <div
      class="bg-gray-50 rounded-lg border-2 border-dashed border-gray-300"
      style={"height: #{@height}"}
    >
      <div class="h-full flex flex-col items-center justify-center p-4">
        <svg class="w-16 h-16 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M13 10V3L4 14h7v7l9-11h-7z"
          />
        </svg>
        <p class="mt-4 text-gray-500 font-medium">Topology Graph</p>
        <p class="text-sm text-gray-400">Layout: <%= @layout %></p>
        <p class="text-sm text-gray-400">Nodes: <%= length(@nodes) %></p>
        <p class="mt-2 text-xs text-gray-400">
          Integration with D3.js or vis.js for interactive graph visualization
        </p>
      </div>
    </div>
    """
  end
end
