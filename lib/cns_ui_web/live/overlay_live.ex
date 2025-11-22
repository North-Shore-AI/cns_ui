defmodule CnsUiWeb.OverlayLive do
  @moduledoc """
  CNS overlay dashboard layered on top of shared CNS UI primitives.
  """
  use CnsUiWeb, :live_view

  alias CnsUi.CNS
  alias CnsUi.Client
  import CnsUiWeb.Components.Shared

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(CnsUi.PubSub, "runs:list")

    {:ok, load_state(socket)}
  end

  @impl true
  def handle_event("select_run", %{"run_id" => run_id}, socket) do
    {:noreply, assign(socket, :selected_run_id, run_id)}
  end

  @impl true
  def handle_info({:run_updated, run}, socket) do
    {:noreply, update_run(run, socket)}
  end

  @impl true
  def handle_info({:run_created, run}, socket) do
    {:noreply, update_run(run, socket)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        CNS Overlay
        <:subtitle>Overlay health, routes, and run telemetry using shared components.</:subtitle>
      </.header>

      <div class="mt-6 grid grid-cols-1 gap-4 md:grid-cols-4">
        <.stat_card
          title="Overlays"
          value={length(@overlays)}
          hint="Total overlay shards"
          icon="hero-squares-2x2"
        />
        <.stat_card
          title="Healthy"
          value={healthy_count(@overlays)}
          hint="Ready for CNS traffic"
          icon="hero-heart"
          tone={:success}
        />
        <.stat_card
          title="Active Sessions"
          value={session_count(@overlays)}
          hint="Across all overlays"
          icon="hero-signal"
        />
        <.stat_card
          title="Routes"
          value={length(@routes)}
          hint="Overlay interconnects"
          icon="hero-arrow-path-rounded-square"
        />
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div class="bg-white shadow rounded-lg p-6 border border-zinc-100">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-semibold text-zinc-900">Overlay Shards</h3>
            <span class="text-xs text-zinc-500">namespace: <%= @namespace %></span>
          </div>
          <div class="space-y-3">
            <div
              :for={overlay <- @overlays}
              class="flex items-center justify-between rounded-lg border border-zinc-100 px-3 py-2"
            >
              <div>
                <p class="text-sm font-semibold text-zinc-900"><%= overlay.id %></p>
                <p class="text-xs text-zinc-500">
                  region: <%= overlay.region %> • capacity: <%= overlay.capacity || "n/a" %>
                </p>
              </div>
              <div class="flex items-center gap-3">
                <p class="text-xs text-zinc-500">
                  sessions: <%= overlay.active_sessions || 0 %>
                </p>
                <.status_badge status={overlay.status} />
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white shadow rounded-lg p-6 border border-zinc-100">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-semibold text-zinc-900">Routes</h3>
            <span class="text-xs text-zinc-500">latency + health</span>
          </div>
          <table class="min-w-full divide-y divide-zinc-100 text-sm">
            <thead>
              <tr class="text-left text-xs text-zinc-500 uppercase tracking-wide">
                <th class="py-2">Source</th>
                <th class="py-2">Target</th>
                <th class="py-2">Latency</th>
                <th class="py-2">Errors</th>
                <th class="py-2">Status</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-zinc-50 text-zinc-800">
              <tr :for={route <- @routes}>
                <td class="py-2 font-medium"><%= route.source %></td>
                <td class="py-2"><%= route.target %></td>
                <td class="py-2"><%= route.latency_ms || "n/a" %> ms</td>
                <td class="py-2"><%= format_error(route.error_rate) %></td>
                <td class="py-2">
                  <.status_badge status={route.status} />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="mt-8 bg-white shadow rounded-lg p-6 border border-zinc-100">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h3 class="text-sm font-semibold text-zinc-900">Run Stream</h3>
            <p class="text-xs text-zinc-500">Filtered to CNS experiments</p>
          </div>
          <form phx-change="select_run">
            <label class="sr-only" for="run_id">Run</label>
            <select id="run_id" name="run_id" class="rounded-md border border-zinc-200 text-sm">
              <option :for={run <- @runs} value={run.id} selected={run.id == @selected_run_id}>
                <%= run_label(run) %>
              </option>
            </select>
          </form>
        </div>

        <%= if @selected_run_id do %>
          <.live_component
            module={CnsUiWeb.Components.RunStream}
            id={"run-stream-#{@selected_run_id}"}
            run_id={@selected_run_id}
          />
        <% else %>
          <p class="text-sm text-zinc-500">No runs available yet.</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp load_state(socket) do
    {:ok, overlays} = CNS.list_overlays()
    {:ok, routes} = CNS.list_routes()
    {:ok, runs} = Client.list_runs(filters: %{"domain" => "cns"})

    normalized_runs = Enum.map(runs, &normalize_run/1)

    selected_run_id =
      normalized_runs
      |> List.first()
      |> case do
        nil -> nil
        run -> run.id
      end

    socket
    |> assign(:overlays, overlays)
    |> assign(:routes, routes)
    |> assign(:runs, normalized_runs)
    |> assign(:selected_run_id, selected_run_id)
    |> assign(:namespace, overlays |> List.first() |> then(&(&1 && &1.namespace)) || "local")
  end

  defp update_run(run, socket) do
    run_id = to_string(run.id)

    runs =
      socket.assigns.runs
      |> Enum.map(fn r -> if r.id == run_id, do: %{r | status: run.status}, else: r end)

    socket
    |> assign(:runs, runs)
    |> assign(:selected_run_id, socket.assigns.selected_run_id || run_id)
  end

  defp healthy_count(overlays),
    do: Enum.count(overlays, &(to_string(&1.status) |> String.downcase() == "healthy"))

  defp session_count(overlays),
    do: overlays |> Enum.map(&(&1.active_sessions || 0)) |> Enum.sum()

  defp format_error(nil), do: "n/a"

  defp format_error(rate) when is_float(rate),
    do: :io_lib.format("~.2f%", [rate * 100]) |> to_string()

  defp format_error(rate), do: rate

  defp run_label(run), do: "Run #{run.id} — #{String.capitalize(to_string(run.status))}"

  defp normalize_run(%{"id" => id} = run) do
    %{
      id: to_string(id),
      status: Map.get(run, "status"),
      experiment_id: Map.get(run, "experiment_id"),
      progress: Map.get(run, "progress")
    }
  end

  defp normalize_run(%{id: id} = run) do
    %{
      id: to_string(id),
      status: Map.get(run, :status),
      experiment_id: Map.get(run, :experiment_id),
      progress: Map.get(run, :progress)
    }
  end
end
