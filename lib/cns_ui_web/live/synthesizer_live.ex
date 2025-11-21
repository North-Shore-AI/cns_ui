defmodule CnsUiWeb.SynthesizerLive do
  @moduledoc """
  Synthesizer results display LiveView.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.SNOs

  @impl true
  def mount(_params, _session, socket) do
    synthesized = SNOs.list_snos(status: "synthesized", limit: 20)

    {:ok,
     socket
     |> assign(:page_title, "Synthesizer")
     |> assign(:synthesized_snos, synthesized)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        Synthesizer
        <:subtitle>View synthesis results and evidence grounding</:subtitle>
      </.header>

      <div class="bg-white shadow rounded-lg p-6">
        <h3 class="text-lg font-semibold mb-4">Recent Syntheses</h3>
        <%= if length(@synthesized_snos) > 0 do %>
          <div class="space-y-4">
            <%= for sno <- @synthesized_snos do %>
              <div class="p-4 border rounded-lg">
                <div class="flex justify-between items-start">
                  <.link
                    navigate={~p"/snos/#{sno.id}"}
                    class="font-medium text-blue-600 hover:text-blue-800"
                  >
                    SNO #<%= sno.id %>
                  </.link>
                  <span class="text-sm">
                    Confidence: <%= Float.round(sno.confidence * 100, 1) %>%
                  </span>
                </div>
                <p class="text-sm text-gray-700 mt-2"><%= sno.claim %></p>
                <div class="mt-3 grid grid-cols-2 gap-4 text-xs text-gray-500">
                  <div>
                    Evidence keys: <%= map_size(sno.evidence) %>
                  </div>
                  <div>
                    Created: <%= Calendar.strftime(sno.inserted_at, "%Y-%m-%d %H:%M") %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <p class="text-gray-500 text-sm text-center py-8">No synthesized SNOs yet</p>
        <% end %>
      </div>
    </div>
    """
  end
end
