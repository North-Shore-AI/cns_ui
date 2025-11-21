defmodule CnsUiWeb.SNOLive.Index do
  @moduledoc """
  SNO browser LiveView with filterable list/grid/graph views.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.SNOs

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "SNOs")
     |> assign(:view_mode, "list")
     |> assign(:search, "")
     |> assign(:status_filter, nil)
     |> assign(:min_confidence, 0.0)
     |> load_snos()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, socket |> assign(:search, search) |> load_snos()}
  end

  @impl true
  def handle_event("search", %{"value" => search}, socket) do
    {:noreply, socket |> assign(:search, search) |> load_snos()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    status = if status == "", do: nil, else: status
    {:noreply, socket |> assign(:status_filter, status) |> load_snos()}
  end

  @impl true
  def handle_event("filter_confidence", %{"confidence" => confidence}, socket) do
    {min, _} = Float.parse(confidence)
    {:noreply, socket |> assign(:min_confidence, min / 100) |> load_snos()}
  end

  @impl true
  def handle_event("set_view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  defp load_snos(socket) do
    filters = build_filters(socket.assigns)
    assign(socket, :snos, SNOs.list_snos(filters))
  end

  defp build_filters(assigns) do
    filters = []
    filters = if assigns.search != "", do: [{:search, assigns.search} | filters], else: filters

    filters =
      if assigns.status_filter, do: [{:status, assigns.status_filter} | filters], else: filters

    filters =
      if assigns.min_confidence > 0,
        do: [{:min_confidence, assigns.min_confidence} | filters],
        else: filters

    filters
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        Structured Narrative Objects
        <:subtitle>Browse and filter SNOs in the system</:subtitle>
      </.header>

      <%!-- Filters --%>
      <div class="bg-white shadow rounded-lg p-4">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Search</label>
            <input
              type="text"
              phx-keyup="search"
              phx-debounce="300"
              name="search"
              value={@search}
              placeholder="Search claims..."
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Status</label>
            <select
              phx-change="filter_status"
              name="status"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
            >
              <option value="">All</option>
              <option value="pending">Pending</option>
              <option value="validated">Validated</option>
              <option value="rejected">Rejected</option>
              <option value="synthesized">Synthesized</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">
              Min Confidence: <%= round(@min_confidence * 100) %>%
            </label>
            <input
              type="range"
              phx-change="filter_confidence"
              name="confidence"
              min="0"
              max="100"
              value={round(@min_confidence * 100)}
              class="mt-1 block w-full"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">View</label>
            <div class="mt-1 flex space-x-2">
              <button
                phx-click="set_view"
                phx-value-mode="list"
                class={"px-3 py-2 rounded #{if @view_mode == "list", do: "bg-blue-500 text-white", else: "bg-gray-200"}"}
              >
                List
              </button>
              <button
                phx-click="set_view"
                phx-value-mode="grid"
                class={"px-3 py-2 rounded #{if @view_mode == "grid", do: "bg-blue-500 text-white", else: "bg-gray-200"}"}
              >
                Grid
              </button>
            </div>
          </div>
        </div>
      </div>

      <%!-- Results --%>
      <%= if @view_mode == "list" do %>
        <.sno_list snos={@snos} />
      <% else %>
        <.sno_grid snos={@snos} />
      <% end %>
    </div>
    """
  end

  defp sno_list(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg overflow-hidden">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Claim</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Confidence
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <%= for sno <- @snos do %>
            <tr class="hover:bg-gray-50 cursor-pointer" phx-click={JS.navigate(~p"/snos/#{sno.id}")}>
              <td class="px-6 py-4">
                <div class="text-sm text-gray-900 max-w-md truncate"><%= sno.claim %></div>
              </td>
              <td class="px-6 py-4">
                <div class="text-sm text-gray-900"><%= Float.round(sno.confidence * 100, 1) %>%</div>
              </td>
              <td class="px-6 py-4">
                <.status_badge status={sno.status} />
              </td>
              <td class="px-6 py-4 text-sm text-gray-500">
                <%= Calendar.strftime(sno.inserted_at, "%Y-%m-%d") %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
      <%= if @snos == [] do %>
        <div class="p-6 text-center text-gray-500">No SNOs found</div>
      <% end %>
    </div>
    """
  end

  defp sno_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <%= for sno <- @snos do %>
        <.link
          navigate={~p"/snos/#{sno.id}"}
          class="bg-white shadow rounded-lg p-4 hover:shadow-lg transition-shadow"
        >
          <div class="flex justify-between items-start mb-2">
            <.status_badge status={sno.status} />
            <span class="text-sm font-medium">
              <%= Float.round(sno.confidence * 100, 1) %>%
            </span>
          </div>
          <p class="text-sm text-gray-900 line-clamp-3"><%= sno.claim %></p>
          <p class="text-xs text-gray-500 mt-2">
            <%= Calendar.strftime(sno.inserted_at, "%Y-%m-%d %H:%M") %>
          </p>
        </.link>
      <% end %>
      <%= if @snos == [] do %>
        <div class="col-span-3 p-6 text-center text-gray-500">No SNOs found</div>
      <% end %>
    </div>
    """
  end

  defp status_badge(assigns) do
    colors = %{
      "pending" => "bg-gray-100 text-gray-800",
      "validated" => "bg-green-100 text-green-800",
      "rejected" => "bg-red-100 text-red-800",
      "synthesized" => "bg-blue-100 text-blue-800"
    }

    assigns = assign(assigns, :color, Map.get(colors, assigns.status, "bg-gray-100"))

    ~H"""
    <span class={"px-2 py-1 text-xs font-medium rounded #{@color}"}>
      <%= @status %>
    </span>
    """
  end
end
