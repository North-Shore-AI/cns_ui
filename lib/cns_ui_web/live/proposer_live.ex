defmodule CnsUiWeb.ProposerLive do
  @moduledoc """
  Proposer output display LiveView.
  """

  use CnsUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Proposer")
     |> assign(:input_text, "")
     |> assign(:claims, [])}
  end

  @impl true
  def handle_event("extract", %{"input" => input}, socket) do
    # Placeholder for CNS.Proposer integration
    claims = [
      %{
        text: "Example extracted claim from input",
        confidence: 0.85,
        source_highlight: {0, 30}
      }
    ]

    {:noreply, socket |> assign(:input_text, input) |> assign(:claims, claims)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        Proposer
        <:subtitle>Extract claims from text input</:subtitle>
      </.header>

      <div class="grid grid-cols-2 gap-6">
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Input</h3>
          <form phx-submit="extract">
            <textarea
              name="input"
              rows="10"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              placeholder="Enter text to extract claims from..."
            ><%= @input_text %></textarea>
            <.button type="submit" class="mt-4">Extract Claims</.button>
          </form>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-semibold mb-4">Extracted Claims</h3>
          <%= if length(@claims) > 0 do %>
            <div class="space-y-3">
              <%= for {claim, index} <- Enum.with_index(@claims) do %>
                <div class="p-3 border rounded-lg">
                  <div class="flex justify-between items-start">
                    <span class="text-sm font-medium">Claim <%= index + 1 %></span>
                    <span class="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
                      <%= Float.round(claim.confidence * 100, 1) %>%
                    </span>
                  </div>
                  <p class="text-sm text-gray-700 mt-2"><%= claim.text %></p>
                </div>
              <% end %>
            </div>
          <% else %>
            <p class="text-gray-500 text-sm">No claims extracted yet</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
