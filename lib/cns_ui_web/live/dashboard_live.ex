defmodule CnsUiWeb.DashboardLive do
  @moduledoc """
  Dashboard LiveView - Main entry point for CNS UI.

  Displays system health indicators, key CNS metrics, recent SNOs, and active experiments.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.{SNOs, Experiments, Metrics}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(5000, self(), :refresh_metrics)
    end

    {:ok, assign_dashboard_data(socket)}
  end

  @impl true
  def handle_info(:refresh_metrics, socket) do
    {:noreply, assign_dashboard_data(socket)}
  end

  defp assign_dashboard_data(socket) do
    socket
    |> assign(:page_title, "Dashboard")
    |> assign(:recent_snos, SNOs.recent_snos(5))
    |> assign(:sno_counts, SNOs.count_by_status())
    |> assign(:active_experiments, Experiments.active_experiments())
    |> assign(:experiment_counts, Experiments.count_by_status())
    |> assign(:average_metrics, Metrics.average_metrics())
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <.header>
        CNS Dashboard
        <:subtitle>Overview of dialectical reasoning system</:subtitle>
      </.header>

      <%!-- System Health --%>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <.metric_card title="Total SNOs" value={total_count(@sno_counts)} color="blue" />
        <.metric_card title="Active Experiments" value={length(@active_experiments)} color="green" />
        <.metric_card
          title="Avg Entailment"
          value={format_metric(@average_metrics[:avg_entailment])}
          color="purple"
        />
        <.metric_card
          title="Avg Pass Rate"
          value={format_metric(@average_metrics[:avg_pass_rate])}
          color="yellow"
        />
      </div>

      <%!-- SNO Status Distribution --%>
      <div class="bg-white shadow rounded-lg p-6">
        <h3 class="text-lg font-semibold mb-4">SNO Status Distribution</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <.status_badge status="pending" count={Map.get(@sno_counts, "pending", 0)} />
          <.status_badge status="validated" count={Map.get(@sno_counts, "validated", 0)} />
          <.status_badge status="rejected" count={Map.get(@sno_counts, "rejected", 0)} />
          <.status_badge status="synthesized" count={Map.get(@sno_counts, "synthesized", 0)} />
        </div>
      </div>

      <%!-- Recent SNOs --%>
      <div class="bg-white shadow rounded-lg p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold">Recent SNOs</h3>
          <.link navigate={~p"/snos"} class="text-sm text-blue-600 hover:text-blue-800">
            View all
          </.link>
        </div>
        <div class="space-y-3">
          <%= for sno <- @recent_snos do %>
            <.sno_row sno={sno} />
          <% end %>
          <%= if @recent_snos == [] do %>
            <p class="text-gray-500 text-sm">No SNOs yet</p>
          <% end %>
        </div>
      </div>

      <%!-- Active Experiments --%>
      <div class="bg-white shadow rounded-lg p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold">Active Experiments</h3>
          <.link navigate={~p"/experiments"} class="text-sm text-blue-600 hover:text-blue-800">
            View all
          </.link>
        </div>
        <div class="space-y-3">
          <%= for experiment <- @active_experiments do %>
            <.experiment_row experiment={experiment} />
          <% end %>
          <%= if @active_experiments == [] do %>
            <p class="text-gray-500 text-sm">No active experiments</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp metric_card(assigns) do
    color_classes = %{
      "blue" => "bg-blue-50 text-blue-700",
      "green" => "bg-green-50 text-green-700",
      "purple" => "bg-purple-50 text-purple-700",
      "yellow" => "bg-yellow-50 text-yellow-700"
    }

    assigns = assign(assigns, :color_class, Map.get(color_classes, assigns.color, "bg-gray-50"))

    ~H"""
    <div class={"rounded-lg p-4 #{@color_class}"}>
      <p class="text-sm font-medium"><%= @title %></p>
      <p class="text-2xl font-bold mt-1"><%= @value %></p>
    </div>
    """
  end

  defp status_badge(assigns) do
    status_colors = %{
      "pending" => "bg-gray-100 text-gray-800",
      "validated" => "bg-green-100 text-green-800",
      "rejected" => "bg-red-100 text-red-800",
      "synthesized" => "bg-blue-100 text-blue-800"
    }

    assigns = assign(assigns, :color_class, Map.get(status_colors, assigns.status, "bg-gray-100"))

    ~H"""
    <div class={"rounded-lg p-3 #{@color_class}"}>
      <p class="text-xs font-medium uppercase"><%= @status %></p>
      <p class="text-xl font-bold"><%= @count %></p>
    </div>
    """
  end

  defp sno_row(assigns) do
    ~H"""
    <.link navigate={~p"/snos/#{@sno.id}"} class="block p-3 hover:bg-gray-50 rounded-lg border">
      <div class="flex justify-between items-start">
        <p class="text-sm font-medium text-gray-900 truncate flex-1">
          <%= String.slice(@sno.claim, 0, 100) %><%= if String.length(@sno.claim) > 100, do: "..." %>
        </p>
        <span class="ml-2 text-xs text-gray-500">
          <%= Float.round(@sno.confidence * 100, 1) %>%
        </span>
      </div>
      <p class="text-xs text-gray-500 mt-1">
        <%= Calendar.strftime(@sno.inserted_at, "%Y-%m-%d %H:%M") %>
      </p>
    </.link>
    """
  end

  defp experiment_row(assigns) do
    ~H"""
    <.link
      navigate={~p"/experiments/#{@experiment.id}"}
      class="block p-3 hover:bg-gray-50 rounded-lg border"
    >
      <div class="flex justify-between items-center">
        <p class="text-sm font-medium text-gray-900"><%= @experiment.name %></p>
        <span class="text-xs px-2 py-1 rounded bg-green-100 text-green-800">
          <%= @experiment.status %>
        </span>
      </div>
      <p class="text-xs text-gray-500 mt-1">
        <%= if @experiment.description,
          do: String.slice(@experiment.description, 0, 50) <> "...",
          else: "No description" %>
      </p>
    </.link>
    """
  end

  defp total_count(counts) do
    counts |> Map.values() |> Enum.sum()
  end

  defp format_metric(nil), do: "N/A"
  defp format_metric(value) when is_float(value), do: "#{Float.round(value * 100, 1)}%"
  defp format_metric(value), do: to_string(value)
end
