defmodule CnsUiWeb.MetricsLive do
  @moduledoc """
  Quality metrics dashboard LiveView.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.{Metrics, Citations, Challenges}
  alias CrucibleUIWeb.Components, as: CrucibleComponents

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

      <%!-- Key Metrics (shared Crucible components) --%>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <CrucibleComponents.stat_card
          title="Entailment"
          value={format_percent(@avg_entailment)}
          delta={target_delta(@avg_entailment, 0.95)}
          tone="blue"
        />
        <CrucibleComponents.stat_card
          title="Chirality"
          value={format_percent(@avg_chirality)}
          delta={target_delta(@avg_chirality, 0.5)}
          tone="purple"
        />
        <CrucibleComponents.stat_card
          title="Pass Rate"
          value={format_percent(@avg_pass_rate)}
          delta={target_delta(@avg_pass_rate, 0.90)}
          tone="emerald"
        />
        <CrucibleComponents.stat_card
          title="Citation Validity"
          value={format_percent(@avg_validity)}
          delta={target_delta(@avg_validity, 0.85)}
          tone="amber"
        />
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <%!-- Challenge Distribution --%>
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Challenge Distribution</h3>
          <div class="space-y-3">
            <%= for severity <- ["critical", "high", "medium", "low"] do %>
              <CrucibleComponents.progress_bar
                label={String.capitalize(severity)}
                percent={bar_width(@challenge_counts, severity)}
                value={Integer.to_string(Map.get(@challenge_counts, severity, 0))}
                tone={severity_tone(severity)}
              />
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

  defp bar_width(counts, severity) do
    count = Map.get(counts, severity, 0)
    total = counts |> Map.values() |> Enum.sum()
    if total > 0, do: count / total * 100, else: 0
  end

  defp format_metric(nil), do: "N/A"
  defp format_metric(value) when is_float(value), do: Float.round(value, 4)
  defp format_metric(value), do: to_string(value)

  defp format_percent(nil), do: "N/A"

  defp format_percent(value) when is_number(value) do
    (value * 100) |> Float.round(1) |> then(&"#{&1}%")
  end

  defp format_percent(value), do: to_string(value)

  defp target_delta(nil, _target), do: nil

  defp target_delta(value, target) when is_number(value) do
    delta = Float.round((value - target) * 100, 1)

    cond do
      delta > 0 -> "+#{delta}% vs target"
      delta < 0 -> "#{delta}% vs target"
      true -> "On target"
    end
  end

  defp target_delta(_, _), do: nil

  defp severity_tone("critical"), do: "amber"
  defp severity_tone("high"), do: "purple"
  defp severity_tone("medium"), do: "blue"
  defp severity_tone("low"), do: "slate"
  defp severity_tone(_), do: "slate"
end
