defmodule CnsUiWeb.GraphLive do
  @moduledoc """
  Dialectical graph visualization LiveView.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.SNOs

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Graph")
     |> assign(:layout, "force")
     |> assign(:snos, SNOs.list_snos(limit: 50))}
  end

  @impl true
  def handle_event("change_layout", %{"layout" => layout}, socket) do
    {:noreply, assign(socket, :layout, layout)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        Dialectical Graph
        <:subtitle>Visualization of SNO relationships</:subtitle>
      </.header>

      <div class="bg-white shadow rounded-lg p-4">
        <div class="flex space-x-4 mb-4">
          <button
            phx-click="change_layout"
            phx-value-layout="force"
            class={"px-3 py-2 rounded #{if @layout == "force", do: "bg-blue-500 text-white", else: "bg-gray-200"}"}
          >
            Force-Directed
          </button>
          <button
            phx-click="change_layout"
            phx-value-layout="hierarchical"
            class={"px-3 py-2 rounded #{if @layout == "hierarchical", do: "bg-blue-500 text-white", else: "bg-gray-200"}"}
          >
            Hierarchical
          </button>
          <button
            phx-click="change_layout"
            phx-value-layout="radial"
            class={"px-3 py-2 rounded #{if @layout == "radial", do: "bg-blue-500 text-white", else: "bg-gray-200"}"}
          >
            Radial
          </button>
        </div>

        <div class="border rounded-lg p-8 min-h-[500px] bg-gray-50 flex items-center justify-center">
          <div class="text-center">
            <p class="text-gray-500">Graph visualization placeholder</p>
            <p class="text-sm text-gray-400 mt-2">
              Layout: <%= @layout %> | SNOs: <%= length(@snos) %>
            </p>
            <p class="text-xs text-gray-400 mt-4">
              D3.js or similar visualization library integration coming soon
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
