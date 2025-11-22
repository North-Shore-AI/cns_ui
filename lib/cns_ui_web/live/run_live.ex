defmodule CnsUiWeb.RunLive do
  @moduledoc """
  Crucible run detail view.

  Shows status/progress for a Crucible job and streams PubSub updates.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.CrucibleClient
  alias CrucibleUIWeb.Components, as: CrucibleComponents

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      CrucibleClient.subscribe_job(id)
    end

    {:ok,
     socket
     |> assign(:page_title, "Run ##{id}")
     |> assign(:job_id, id)
     |> assign(:job, nil)
     |> assign(:job_status, "loading")
     |> assign(:job_progress, 0.0)
     |> assign(:events, [])
     |> load_job()}
  end

  @impl true
  def handle_info({:training_update, %{job_id: job_id} = update}, socket) do
    maybe_update(job_id, update, socket)
  end

  def handle_info({:crucible_training, %{job_id: job_id} = update}, socket) do
    maybe_update(job_id, update, socket)
  end

  def handle_info(%{job_id: job_id} = update, socket) do
    maybe_update(job_id, update, socket)
  end

  defp maybe_update(job_id, update, socket) do
    if job_id == socket.assigns.job_id do
      status = Map.get(update, :status) || Map.get(update, "status") || socket.assigns.job_status

      progress =
        Map.get(update, :progress) || Map.get(update, "progress") || socket.assigns.job_progress

      events = Enum.take([update | socket.assigns.events], 50)

      {:noreply,
       socket
       |> assign(:job_status, status)
       |> assign(:job_progress, to_float(progress))
       |> assign(:events, events)}
    else
      {:noreply, socket}
    end
  end

  defp load_job(socket) do
    case CrucibleClient.get_job(socket.assigns.job_id) do
      {:ok, job} ->
        socket
        |> assign(:job, job)
        |> assign(:job_status, Map.get(job, "status", "unknown"))
        |> assign(:job_progress, to_float(Map.get(job, "progress", 0)))

      {:error, _reason} ->
        put_flash(socket, :error, "Unable to load Crucible job")
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.back navigate={~p"/training"}>Back to Training</.back>

      <.header>
        Crucible Run #<%= @job_id %>
        <:subtitle>Live status from Crucible</:subtitle>
      </.header>

      <div class="bg-white shadow rounded-lg p-6 space-y-4">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-sm text-gray-500">Status</p>
            <p class="text-xl font-semibold text-gray-900"><%= @job_status %></p>
          </div>
          <span class="text-xs px-2 py-1 rounded bg-blue-50 text-blue-700">
            PubSub: <%= Application.get_env(:cns_ui, :crucible_api, []) |> Keyword.get(:pubsub) %>
          </span>
        </div>
        <CrucibleComponents.progress_bar
          label="Progress"
          percent={@job_progress}
          tone="blue"
          value={"#{Float.round(@job_progress, 1)}%"}
        />
      </div>

      <div class="bg-white shadow rounded-lg p-6">
        <h3 class="text-lg font-semibold mb-4">Job Details</h3>
        <%= if @job do %>
          <pre class="text-xs bg-gray-50 rounded p-4 overflow-auto"><%= Jason.encode!(@job, pretty: true) %></pre>
        <% else %>
          <p class="text-sm text-gray-500">Loading job details...</p>
        <% end %>
      </div>

      <div class="bg-white shadow rounded-lg p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold">Live Events</h3>
          <span class="text-xs text-gray-500">Newest first</span>
        </div>
        <div class="space-y-2 max-h-80 overflow-auto">
          <%= for event <- @events do %>
            <div class="border rounded p-3 bg-gray-50 text-xs font-mono">
              <%= inspect(event) %>
            </div>
          <% end %>
          <%= if @events == [] do %>
            <p class="text-sm text-gray-500">No events yet</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp to_float(value) when is_float(value), do: value
  defp to_float(value) when is_integer(value), do: value * 1.0

  defp to_float(value) when is_binary(value) do
    case Float.parse(value) do
      {parsed, _} -> parsed
      _ -> 0.0
    end
  end

  defp to_float(_), do: 0.0
end
