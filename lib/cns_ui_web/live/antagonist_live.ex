defmodule CnsUiWeb.AntagonistLive do
  @moduledoc """
  Antagonist interface for viewing and resolving challenges.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.Challenges

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Antagonist")
     |> assign(:challenges, Challenges.unresolved_challenges())
     |> assign(:filter, "all")}
  end

  @impl true
  def handle_event("filter", %{"type" => type}, socket) do
    challenges =
      if type == "all" do
        Challenges.unresolved_challenges()
      else
        Challenges.list_challenges()
        |> Enum.filter(&(&1.challenge_type == type))
      end

    {:noreply, socket |> assign(:filter, type) |> assign(:challenges, challenges)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        Antagonist
        <:subtitle>Challenge management and resolution</:subtitle>
      </.header>

      <div class="bg-white shadow rounded-lg p-4">
        <div class="flex space-x-2 mb-4">
          <%= for type <- ["all", "contradiction", "insufficient_evidence", "logical_fallacy", "bias"] do %>
            <button
              phx-click="filter"
              phx-value-type={type}
              class={"px-3 py-1 rounded text-sm #{if @filter == type, do: "bg-blue-500 text-white", else: "bg-gray-200"}"}
            >
              <%= String.replace(type, "_", " ") |> String.capitalize() %>
            </button>
          <% end %>
        </div>

        <%= if length(@challenges) > 0 do %>
          <div class="space-y-3">
            <%= for challenge <- @challenges do %>
              <div class="p-4 border rounded-lg">
                <div class="flex justify-between items-start">
                  <div>
                    <span class="font-medium"><%= challenge.challenge_type %></span>
                    <span class={"ml-2 px-2 py-1 text-xs rounded #{severity_color(challenge.severity)}"}>
                      <%= challenge.severity %>
                    </span>
                  </div>
                  <span class="text-xs text-gray-500">SNO #<%= challenge.sno_id %></span>
                </div>
                <p class="text-sm text-gray-700 mt-2"><%= challenge.description %></p>
                <div class="mt-3 flex space-x-2">
                  <button class="px-3 py-1 bg-green-500 text-white rounded text-sm">
                    Resolve
                  </button>
                  <button class="px-3 py-1 bg-gray-200 rounded text-sm">
                    Dismiss
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <p class="text-gray-500 text-sm text-center py-8">No challenges found</p>
        <% end %>
      </div>
    </div>
    """
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
