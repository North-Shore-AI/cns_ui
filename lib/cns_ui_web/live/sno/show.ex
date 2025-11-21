defmodule CnsUiWeb.SNOLive.Show do
  @moduledoc """
  SNO detail view with tabs for overview, structure, evidence, metrics, and graph.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.SNOs

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    sno = SNOs.get_sno_with_associations!(id)

    {:ok,
     socket
     |> assign(:page_title, "SNO Details")
     |> assign(:sno, sno)
     |> assign(:active_tab, "overview")
     |> assign(:synthesis_chain, SNOs.get_synthesis_chain(sno.id))}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.back navigate={~p"/snos"}>Back to SNOs</.back>

      <.header>
        SNO #<%= @sno.id %>
        <:subtitle>
          <span class={"px-2 py-1 text-sm font-medium rounded #{status_color(@sno.status)}"}>
            <%= @sno.status %>
          </span>
        </:subtitle>
      </.header>

      <%!-- Tabs --%>
      <div class="border-b border-gray-200">
        <nav class="-mb-px flex space-x-8">
          <%= for tab <- ["overview", "structure", "evidence", "metrics", "graph"] do %>
            <button
              phx-click="change_tab"
              phx-value-tab={tab}
              class={"border-b-2 py-4 px-1 text-sm font-medium #{if @active_tab == tab, do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
            >
              <%= String.capitalize(tab) %>
            </button>
          <% end %>
        </nav>
      </div>

      <%!-- Tab Content --%>
      <div class="bg-white shadow rounded-lg p-6">
        <%= case @active_tab do %>
          <% "overview" -> %>
            <.overview_tab sno={@sno} />
          <% "structure" -> %>
            <.structure_tab sno={@sno} chain={@synthesis_chain} />
          <% "evidence" -> %>
            <.evidence_tab sno={@sno} />
          <% "metrics" -> %>
            <.metrics_tab sno={@sno} />
          <% "graph" -> %>
            <.graph_tab sno={@sno} />
        <% end %>
      </div>
    </div>
    """
  end

  defp overview_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h4 class="text-sm font-medium text-gray-500">Claim</h4>
        <p class="mt-1 text-gray-900"><%= @sno.claim %></p>
      </div>

      <div class="grid grid-cols-2 gap-6">
        <div>
          <h4 class="text-sm font-medium text-gray-500">Confidence</h4>
          <div class="mt-1 flex items-center">
            <div class="flex-1 bg-gray-200 rounded-full h-2 mr-2">
              <div class="bg-blue-500 h-2 rounded-full" style={"width: #{@sno.confidence * 100}%"}>
              </div>
            </div>
            <span class="text-sm font-medium"><%= Float.round(@sno.confidence * 100, 1) %>%</span>
          </div>
        </div>
        <div>
          <h4 class="text-sm font-medium text-gray-500">Created</h4>
          <p class="mt-1 text-gray-900">
            <%= Calendar.strftime(@sno.inserted_at, "%Y-%m-%d %H:%M:%S") %>
          </p>
        </div>
      </div>

      <div>
        <h4 class="text-sm font-medium text-gray-500">Metadata</h4>
        <pre class="mt-1 p-3 bg-gray-50 rounded text-sm overflow-auto"><%= Jason.encode!(@sno.metadata, pretty: true) %></pre>
      </div>
    </div>
    """
  end

  defp structure_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h4 class="text-sm font-medium text-gray-500 mb-3">Synthesis Chain</h4>
        <div class="space-y-2">
          <%= for {sno, index} <- Enum.with_index(@chain) do %>
            <div class={"p-3 rounded border #{if sno.id == @sno.id, do: "border-blue-500 bg-blue-50", else: "border-gray-200"}"}>
              <div class="flex justify-between">
                <span class="text-sm font-medium">Level <%= index %></span>
                <span class="text-xs text-gray-500">#<%= sno.id %></span>
              </div>
              <p class="text-sm text-gray-700 mt-1 truncate"><%= sno.claim %></p>
            </div>
          <% end %>
        </div>
      </div>

      <%= if length(@sno.children) > 0 do %>
        <div>
          <h4 class="text-sm font-medium text-gray-500 mb-3">Child SNOs</h4>
          <div class="space-y-2">
            <%= for child <- @sno.children do %>
              <.link
                navigate={~p"/snos/#{child.id}"}
                class="block p-3 rounded border border-gray-200 hover:border-blue-500"
              >
                <div class="flex justify-between">
                  <span class="text-sm font-medium">#<%= child.id %></span>
                  <span class="text-xs"><%= Float.round(child.confidence * 100, 1) %>%</span>
                </div>
                <p class="text-sm text-gray-700 mt-1 truncate"><%= child.claim %></p>
              </.link>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp evidence_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h4 class="text-sm font-medium text-gray-500 mb-3">Evidence</h4>
        <pre class="p-3 bg-gray-50 rounded text-sm overflow-auto"><%= Jason.encode!(@sno.evidence, pretty: true) %></pre>
      </div>

      <div>
        <h4 class="text-sm font-medium text-gray-500 mb-3">
          Citations (<%= length(@sno.citations) %>)
        </h4>
        <%= if length(@sno.citations) > 0 do %>
          <div class="space-y-2">
            <%= for citation <- @sno.citations do %>
              <div class="p-3 rounded border border-gray-200">
                <div class="flex justify-between">
                  <span class="text-sm font-medium"><%= citation.source_type %></span>
                  <span class="text-xs text-gray-500"><%= citation.source_id %></span>
                </div>
                <div class="mt-2 grid grid-cols-2 gap-2 text-xs">
                  <div>
                    Validity: <%= if citation.validity_score,
                      do: "#{Float.round(citation.validity_score * 100, 1)}%",
                      else: "N/A" %>
                  </div>
                  <div>
                    Grounding: <%= if citation.grounding_score,
                      do: "#{Float.round(citation.grounding_score * 100, 1)}%",
                      else: "N/A" %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <p class="text-gray-500 text-sm">No citations</p>
        <% end %>
      </div>

      <div>
        <h4 class="text-sm font-medium text-gray-500 mb-3">Provenance</h4>
        <pre class="p-3 bg-gray-50 rounded text-sm overflow-auto"><%= Jason.encode!(@sno.provenance, pretty: true) %></pre>
      </div>
    </div>
    """
  end

  defp metrics_tab(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h4 class="text-sm font-medium text-gray-500 mb-3">
          Challenges (<%= length(@sno.challenges) %>)
        </h4>
        <%= if length(@sno.challenges) > 0 do %>
          <div class="space-y-2">
            <%= for challenge <- @sno.challenges do %>
              <div class="p-3 rounded border border-gray-200">
                <div class="flex justify-between items-start">
                  <span class="text-sm font-medium"><%= challenge.challenge_type %></span>
                  <span class={"px-2 py-1 text-xs rounded #{severity_color(challenge.severity)}"}>
                    <%= challenge.severity %>
                  </span>
                </div>
                <p class="text-sm text-gray-700 mt-2"><%= challenge.description %></p>
                <%= if challenge.resolution do %>
                  <p class="text-sm text-green-700 mt-2">
                    <strong>Resolution:</strong> <%= challenge.resolution %>
                  </p>
                <% end %>
              </div>
            <% end %>
          </div>
        <% else %>
          <p class="text-gray-500 text-sm">No challenges</p>
        <% end %>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div class="p-4 bg-gray-50 rounded">
          <h4 class="text-sm font-medium text-gray-500">Confidence Score</h4>
          <p class="text-2xl font-bold mt-1"><%= Float.round(@sno.confidence * 100, 1) %>%</p>
        </div>
        <div class="p-4 bg-gray-50 rounded">
          <h4 class="text-sm font-medium text-gray-500">Citation Count</h4>
          <p class="text-2xl font-bold mt-1"><%= length(@sno.citations) %></p>
        </div>
      </div>
    </div>
    """
  end

  defp graph_tab(assigns) do
    ~H"""
    <div class="text-center py-12">
      <p class="text-gray-500">Graph visualization coming soon</p>
      <p class="text-sm text-gray-400 mt-2">
        Will display relationships between this SNO and related entities
      </p>
    </div>
    """
  end

  defp status_color(status) do
    case status do
      "pending" -> "bg-gray-100 text-gray-800"
      "validated" -> "bg-green-100 text-green-800"
      "rejected" -> "bg-red-100 text-red-800"
      "synthesized" -> "bg-blue-100 text-blue-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp severity_color(severity) do
    case severity do
      "low" -> "bg-gray-100 text-gray-800"
      "medium" -> "bg-yellow-100 text-yellow-800"
      "high" -> "bg-orange-100 text-orange-800"
      "critical" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
