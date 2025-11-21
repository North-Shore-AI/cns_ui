defmodule CnsUiWeb.ExperimentLive.Index do
  @moduledoc """
  Experiment management index LiveView.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.Experiments

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Experiments")
     |> assign(:experiments, Experiments.list_experiments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Experiment")
    |> assign(:experiment, %Experiments.Experiment{})
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        Experiments
        <:actions>
          <.link navigate={~p"/experiments/new"}>
            <.button>New Experiment</.button>
          </.link>
        </:actions>
      </.header>

      <div class="bg-white shadow rounded-lg overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for experiment <- @experiments do %>
              <tr class="hover:bg-gray-50">
                <td class="px-6 py-4">
                  <.link
                    navigate={~p"/experiments/#{experiment.id}"}
                    class="text-blue-600 hover:text-blue-800"
                  >
                    <%= experiment.name %>
                  </.link>
                  <p class="text-xs text-gray-500 mt-1"><%= experiment.description %></p>
                </td>
                <td class="px-6 py-4">
                  <.status_badge status={experiment.status} />
                </td>
                <td class="px-6 py-4 text-sm text-gray-500">
                  <%= Calendar.strftime(experiment.inserted_at, "%Y-%m-%d") %>
                </td>
                <td class="px-6 py-4">
                  <.link
                    navigate={~p"/experiments/#{experiment.id}"}
                    class="text-blue-600 hover:text-blue-800 text-sm"
                  >
                    View
                  </.link>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <%= if @experiments == [] do %>
          <div class="p-6 text-center text-gray-500">No experiments yet</div>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_badge(assigns) do
    colors = %{
      "pending" => "bg-gray-100 text-gray-800",
      "running" => "bg-blue-100 text-blue-800",
      "completed" => "bg-green-100 text-green-800",
      "failed" => "bg-red-100 text-red-800",
      "cancelled" => "bg-yellow-100 text-yellow-800"
    }

    assigns = assign(assigns, :color, Map.get(colors, assigns.status, "bg-gray-100"))

    ~H"""
    <span class={"px-2 py-1 text-xs font-medium rounded #{@color}"}>
      <%= @status %>
    </span>
    """
  end
end
