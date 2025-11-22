defmodule CnsUiWeb.Components.RunStream do
  @moduledoc """
  LiveComponent that streams training run updates over PubSub for embed in CNS overlay views.
  """
  use CnsUiWeb, :live_component

  alias CnsUi.Training
  import CnsUiWeb.Components.Shared

  @impl true
  def update(%{run_id: run_id} = assigns, socket) do
    topic = "run:#{run_id}"

    socket =
      socket
      |> assign_new(:run, fn -> Training.get_training_run!(run_id) end)
      |> assign(:run_id, run_id)
      |> assign(:run_topic, topic)
      |> maybe_subscribe(topic)

    {:ok, assign(socket, assigns)}
  end

  def handle_info({:run_updated, run}, %{assigns: %{run_id: id}} = socket) when run.id == id do
    {:noreply, assign(socket, :run, run)}
  end

  def handle_info({:run_created, run}, %{assigns: %{run_id: id}} = socket) when run.id == id do
    {:noreply, assign(socket, :run, run)}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-4 border border-zinc-100">
      <div class="flex items-start justify-between mb-3">
        <div>
          <p class="text-xs uppercase tracking-wide text-zinc-500">Run</p>
          <p class="text-sm font-semibold text-zinc-900">#<%= @run.id %></p>
        </div>
        <.status_badge status={@run.status} />
      </div>

      <dl class="grid grid-cols-2 gap-3 text-sm text-zinc-700">
        <div>
          <dt class="text-xs text-zinc-500">Experiment</dt>
          <dd class="font-medium"><%= @run.experiment_id %></dd>
        </div>
        <div>
          <dt class="text-xs text-zinc-500">Created</dt>
          <dd class="font-medium"><%= datetime_label(@run.inserted_at) %></dd>
        </div>
        <div>
          <dt class="text-xs text-zinc-500">Updated</dt>
          <dd class="font-medium"><%= datetime_label(@run.updated_at) %></dd>
        </div>
        <div>
          <dt class="text-xs text-zinc-500">Progress</dt>
          <dd class="font-medium">
            <%= progress_label(@run.metrics) %>
          </dd>
        </div>
      </dl>
    </div>
    """
  end

  defp maybe_subscribe(socket, topic) do
    if connected?(socket) and socket.assigns[:subscribed_topic] != topic do
      Phoenix.PubSub.subscribe(CnsUi.PubSub, topic)
      assign(socket, :subscribed_topic, topic)
    else
      socket
    end
  end

  defp datetime_label(nil), do: "—"

  defp datetime_label(%NaiveDateTime{} = dt),
    do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")

  defp progress_label(%{"progress" => progress}) when is_number(progress),
    do: "#{Float.round(progress * 100, 1)}%"

  defp progress_label(%{progress: progress}) when is_number(progress),
    do: "#{Float.round(progress * 100, 1)}%"

  defp progress_label(_), do: "n/a"
end
