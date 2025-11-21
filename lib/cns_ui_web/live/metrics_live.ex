defmodule CnsUiWeb.MetricsLive do
  @moduledoc """
  Quality metrics dashboard LiveView.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.{Metrics, Citations, Challenges}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(5000, self(), :refresh)
    end

    {:ok, load_metrics(socket)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    {:noreply, load_metrics(socket)}
  end

  defp load_metrics(socket) do
    avg_metrics = Metrics.average_metrics()

    socket
    |> assign(:page_title, "Metrics")
    |> assign(:avg_entailment, avg_metrics[:avg_entailment])
    |> assign(:avg_chirality, avg_metrics[:avg_chirality])
    |> assign(:avg_fisher_rao, avg_metrics[:avg_fisher_rao])
    |> assign(:avg_pass_rate, avg_metrics[:avg_pass_rate])
    |> assign(:avg_validity, Citations.average_validity_score())
    |> assign(:challenge_counts, Challenges.count_by_severity())
    |> assign(:citation_counts, Citations.citations_by_type())
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        Quality Metrics
        <:subtitle>CNS 3.0 metrics dashboard</:subtitle>
      </.header>

      <%!-- Key Metrics --%>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <.metric_gauge title="Entailment" value={@avg_entailment} target={0.95} color="blue" />
        <.metric_gauge title="Chirality" value={@avg_chirality} target={0.5} color="purple" />
        <.metric_gauge title="Pass Rate" value={@avg_pass_rate} target={0.90} color="green" />
        <.metric_gauge title="Citation Validity" value={@avg_validity} target={0.85} color="yellow" />
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <%!-- Challenge Distribution --%>
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Challenge Distribution</h3>
          <div class="space-y-3">
            <%= for severity <- ["critical", "high", "medium", "low"] do %>
              <div class="flex items-center">
                <span class="w-20 text-sm"><%= severity %></span>
                <div class="flex-1 h-4 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    class={"h-full #{severity_bar_color(severity)}"}
                    style={"width: #{bar_width(@challenge_counts, severity)}%"}
                  >
                  </div>
                </div>
                <span class="w-8 text-right text-sm">
                  <%= Map.get(@challenge_counts, severity, 0) %>
                </span>
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Citation Types --%>
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Citations by Type</h3>
          <div class="space-y-3">
            <%= for {type, count} <- @citation_counts do %>
              <div class="flex justify-between items-center p-2 bg-gray-50 rounded">
                <span class="text-sm font-medium"><%= type %></span>
                <span class="text-sm text-gray-600"><%= count %></span>
              </div>
            <% end %>
            <%= if map_size(@citation_counts) == 0 do %>
              <p class="text-gray-500 text-sm">No citations yet</p>
            <% end %>
          </div>
        </div>
      </div>

      <%!-- Fisher-Rao Placeholder --%>
      <div class="bg-white shadow rounded-lg p-6">
        <h3 class="text-lg font-semibold mb-4">Fisher-Rao Metric</h3>
        <div class="h-64 bg-gray-50 rounded flex items-center justify-center">
          <div class="text-center">
            <p class="text-gray-500">Fisher-Rao heatmap visualization</p>
            <p class="text-sm text-gray-400 mt-2">
              Current average: <%= format_metric(@avg_fisher_rao) %>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp metric_gauge(assigns) do
    value = assigns.value || 0
    percentage = if is_number(value), do: value * 100, else: 0
    on_target = percentage >= assigns.target * 100

    colors = %{
      "blue" => "text-blue-600",
      "purple" => "text-purple-600",
      "green" => "text-green-600",
      "yellow" => "text-yellow-600"
    }

    assigns =
      assigns
      |> assign(:percentage, percentage)
      |> assign(:on_target, on_target)
      |> assign(:text_color, Map.get(colors, assigns.color, "text-gray-600"))

    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <h4 class="text-sm font-medium text-gray-500"><%= @title %></h4>
      <div class="mt-2 flex items-baseline">
        <span class={"text-3xl font-bold #{@text_color}"}>
          <%= Float.round(@percentage, 1) %>%
        </span>
        <span class={"ml-2 text-xs #{if @on_target, do: "text-green-500", else: "text-red-500"}"}>
          <%= if @on_target, do: "On target", else: "Below target" %>
        </span>
      </div>
      <div class="mt-2 h-2 bg-gray-200 rounded-full">
        <div
          class={"h-2 rounded-full #{if @on_target, do: "bg-green-500", else: "bg-red-400"}"}
          style={"width: #{min(@percentage, 100)}%"}
        >
        </div>
      </div>
      <p class="mt-1 text-xs text-gray-400">Target: <%= @target * 100 %>%</p>
    </div>
    """
  end

  defp severity_bar_color(severity) do
    case severity do
      "critical" -> "bg-red-500"
      "high" -> "bg-orange-500"
      "medium" -> "bg-yellow-500"
      "low" -> "bg-gray-400"
      _ -> "bg-gray-300"
    end
  end

  defp bar_width(counts, severity) do
    count = Map.get(counts, severity, 0)
    total = counts |> Map.values() |> Enum.sum()
    if total > 0, do: count / total * 100, else: 0
  end

  defp format_metric(nil), do: "N/A"
  defp format_metric(value) when is_float(value), do: Float.round(value, 4)
  defp format_metric(value), do: to_string(value)
end
