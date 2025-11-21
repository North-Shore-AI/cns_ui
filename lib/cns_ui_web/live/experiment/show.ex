defmodule CnsUiWeb.ExperimentLive.Show do
  @moduledoc """
  Experiment detail view with training runs.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.{Experiments, Training}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    experiment = Experiments.get_experiment_with_runs!(id)

    {:ok,
     socket
     |> assign(:page_title, experiment.name)
     |> assign(:experiment, experiment)
     |> assign(:training_runs, Training.list_training_runs_for_experiment(experiment.id))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params), do: socket
  defp apply_action(socket, :edit, _params), do: assign(socket, :page_title, "Edit Experiment")

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.back navigate={~p"/experiments"}>Back to Experiments</.back>

      <.header>
        <%= @experiment.name %>
        <:subtitle>
          <.status_badge status={@experiment.status} />
        </:subtitle>
      </.header>

      <div class="bg-white shadow rounded-lg p-6 space-y-4">
        <div>
          <h4 class="text-sm font-medium text-gray-500">Description</h4>
          <p class="mt-1 text-gray-900"><%= @experiment.description || "No description" %></p>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <h4 class="text-sm font-medium text-gray-500">Dataset Path</h4>
            <p class="mt-1 text-gray-900"><%= @experiment.dataset_path || "Not specified" %></p>
          </div>
          <div>
            <h4 class="text-sm font-medium text-gray-500">Created</h4>
            <p class="mt-1 text-gray-900">
              <%= Calendar.strftime(@experiment.inserted_at, "%Y-%m-%d %H:%M:%S") %>
            </p>
          </div>
        </div>

        <div>
          <h4 class="text-sm font-medium text-gray-500">Configuration</h4>
          <pre class="mt-1 p-3 bg-gray-50 rounded text-sm overflow-auto"><%= Jason.encode!(@experiment.config, pretty: true) %></pre>
        </div>
      </div>

      <div class="bg-white shadow rounded-lg p-6">
        <h3 class="text-lg font-semibold mb-4">Training Runs</h3>
        <%= if length(@training_runs) > 0 do %>
          <div class="space-y-3">
            <%= for run <- @training_runs do %>
              <div class="p-4 border rounded-lg">
                <div class="flex justify-between items-start">
                  <div>
                    <span class="font-medium">Run #<%= run.id %></span>
                    <.status_badge status={run.status} />
                  </div>
                  <span class="text-sm text-gray-500">
                    <%= Calendar.strftime(run.inserted_at, "%Y-%m-%d %H:%M") %>
                  </span>
                </div>
                <%= if map_size(run.lora_config) > 0 do %>
                  <div class="mt-2 text-sm text-gray-600">
                    LoRA: rank=<%= run.lora_config["rank"] || "N/A" %>, alpha=<%= run.lora_config[
                      "alpha"
                    ] || "N/A" %>
                  </div>
                <% end %>
                <%= if length(run.checkpoints) > 0 do %>
                  <div class="mt-2 text-sm text-gray-500">
                    Checkpoints: <%= length(run.checkpoints) %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% else %>
          <p class="text-gray-500 text-sm">No training runs yet</p>
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
    <span class={"ml-2 px-2 py-1 text-xs font-medium rounded #{@color}"}>
      <%= @status %>
    </span>
    """
  end
end
