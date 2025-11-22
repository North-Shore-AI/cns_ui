defmodule CnsUiWeb.TrainingLive do
  @moduledoc """
  Training configuration LiveView with 6-step wizard.
  """

  use CnsUiWeb, :live_view

  alias CnsUi.CrucibleClient
  alias CrucibleUIWeb.Components, as: CrucibleComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Training")
     |> assign(:step, 1)
     |> assign(:submitting?, false)
     |> assign(:job, nil)
     |> assign(:job_status, nil)
     |> assign(:job_progress, 0)
     |> assign(:config, %{
       dataset_path: "",
       model: "llama-7b",
       lora_rank: 8,
       lora_alpha: 16,
       lora_dropout: 0.1,
       citation_validity_weight: 0.5,
       learning_rate: 0.0001,
       epochs: 3
     })}
  end

  @impl true
  def handle_event("next_step", _params, socket) do
    {:noreply, assign(socket, :step, min(socket.assigns.step + 1, 6))}
  end

  @impl true
  def handle_event("prev_step", _params, socket) do
    {:noreply, assign(socket, :step, max(socket.assigns.step - 1, 1))}
  end

  @impl true
  def handle_event("update_config", %{"config" => config}, socket) do
    updated_config =
      socket.assigns.config
      |> Map.merge(atomize_keys(config))
      |> normalize_config()

    {:noreply, assign(socket, :config, updated_config)}
  end

  @impl true
  def handle_event("start_training", _params, socket) do
    payload = build_job_payload(socket.assigns.config)

    socket = assign(socket, :submitting?, true)

    case CrucibleClient.create_job(payload) do
      {:ok, %{"id" => job_id} = job} ->
        CrucibleClient.subscribe_job(job_id)

        {:noreply,
         socket
         |> assign(:job, job)
         |> assign(:job_status, Map.get(job, "status", "submitted"))
         |> assign(:job_progress, to_float(Map.get(job, "progress", 0)))
         |> assign(:step, 6)
         |> assign(:submitting?, false)
         |> put_flash(:info, "Crucible training job submitted (##{job_id})")
         |> push_navigate(to: ~p"/runs/#{job_id}")}

      {:ok, job} ->
        {:noreply,
         socket
         |> assign(:job, job)
         |> assign(:job_status, Map.get(job, "status", "submitted"))
         |> assign(:job_progress, to_float(Map.get(job, "progress", 0)))
         |> assign(:step, 6)
         |> assign(:submitting?, false)
         |> put_flash(:info, "Crucible training job submitted")
         |> push_navigate(to: ~p"/runs/#{Map.get(job, "id", "unknown")}")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:submitting?, false)
         |> put_flash(:error, "Failed to submit job: #{format_error(reason)}")}
    end
  end

  @impl true
  def handle_info({:training_update, %{job_id: job_id} = update}, socket) do
    maybe_update_job(job_id, update, socket)
  end

  def handle_info({:crucible_training, %{job_id: job_id} = update}, socket) do
    maybe_update_job(job_id, update, socket)
  end

  def handle_info(%{job_id: job_id} = update, socket) do
    maybe_update_job(job_id, update, socket)
  end

  defp atomize_keys(map) do
    Map.new(map, fn {k, v} ->
      try do
        {String.to_existing_atom(k), v}
      rescue
        _ -> {k, v}
      end
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        Training Configuration
        <:subtitle>Step <%= @step %> of 6</:subtitle>
      </.header>

      <%= if @job_status do %>
        <div class="bg-white shadow rounded-lg p-4">
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm text-gray-500">Crucible Job</p>
              <p class="text-lg font-semibold text-gray-900">
                <%= @job_status %>
                <%= if @job && @job["id"], do: "(##{@job["id"]})" %>
              </p>
            </div>
            <span class="text-xs px-2 py-1 rounded bg-blue-50 text-blue-700">
              Synced with Crucible API
            </span>
          </div>
          <div class="mt-4">
            <CrucibleComponents.progress_bar
              label="Progress"
              percent={@job_progress}
              tone="blue"
              value={"#{Float.round(@job_progress, 1)}%"}
            />
          </div>
        </div>
      <% end %>

      <%!-- Progress bar --%>
      <div class="bg-white shadow rounded-lg p-4">
        <div class="flex justify-between mb-2">
          <%= for i <- 1..6 do %>
            <div class={"flex items-center justify-center w-8 h-8 rounded-full text-sm font-medium #{if i <= @step, do: "bg-blue-500 text-white", else: "bg-gray-200"}"}>
              <%= i %>
            </div>
          <% end %>
        </div>
        <div class="h-2 bg-gray-200 rounded-full">
          <div
            class="h-2 bg-blue-500 rounded-full transition-all"
            style={"width: #{(@step / 6) * 100}%"}
          >
          </div>
        </div>
      </div>

      <div class="bg-white shadow rounded-lg p-6">
        <%= case @step do %>
          <% 1 -> %>
            <.step_dataset config={@config} />
          <% 2 -> %>
            <.step_model config={@config} />
          <% 3 -> %>
            <.step_lora config={@config} />
          <% 4 -> %>
            <.step_weights config={@config} />
          <% 5 -> %>
            <.step_hyperparams config={@config} />
          <% 6 -> %>
            <.step_review config={@config} />
        <% end %>

        <div class="mt-6 flex justify-between">
          <button
            phx-click="prev_step"
            class={"px-4 py-2 rounded #{if @step == 1, do: "bg-gray-100 text-gray-400 cursor-not-allowed", else: "bg-gray-200 hover:bg-gray-300"}"}
            disabled={@step == 1}
          >
            Previous
          </button>
          <%= if @step == 6 do %>
            <button
              phx-click="start_training"
              class="px-4 py-2 bg-green-500 text-white rounded disabled:opacity-70"
              disabled={@submitting?}
              phx-disable-with="Submitting..."
            >
              Start Training
            </button>
          <% else %>
            <button phx-click="next_step" class="px-4 py-2 bg-blue-500 text-white rounded">
              Next
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp step_dataset(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-semibold mb-4">Step 1: Dataset</h3>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700">Dataset Path</label>
          <input
            type="text"
            value={@config.dataset_path}
            phx-change="update_config"
            name="config[dataset_path]"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            placeholder="/path/to/dataset.json"
          />
        </div>
        <div class="p-4 bg-gray-50 rounded-lg">
          <p class="text-sm text-gray-600">
            Upload or specify the path to your training dataset.
            Supported formats: JSON, JSONL, CSV
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp step_model(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-semibold mb-4">Step 2: Model Selection</h3>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700">Base Model</label>
          <select
            name="config[model]"
            phx-change="update_config"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          >
            <option value="llama-7b" selected={@config.model == "llama-7b"}>LLaMA 7B</option>
            <option value="llama-13b" selected={@config.model == "llama-13b"}>LLaMA 13B</option>
            <option value="mistral-7b" selected={@config.model == "mistral-7b"}>Mistral 7B</option>
          </select>
        </div>
      </div>
    </div>
    """
  end

  defp step_lora(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-semibold mb-4">Step 3: LoRA Configuration</h3>
      <div class="space-y-4">
        <div class="grid grid-cols-3 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">Rank</label>
            <input
              type="number"
              value={@config.lora_rank}
              name="config[lora_rank]"
              phx-change="update_config"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Alpha</label>
            <input
              type="number"
              value={@config.lora_alpha}
              name="config[lora_alpha]"
              phx-change="update_config"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Dropout</label>
            <input
              type="number"
              step="0.01"
              value={@config.lora_dropout}
              name="config[lora_dropout]"
              phx-change="update_config"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp step_weights(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-semibold mb-4">Step 4: Weight Settings</h3>
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700">
            Citation Validity Weight: <%= @config.citation_validity_weight %>
          </label>
          <input
            type="range"
            min="0"
            max="1"
            step="0.1"
            value={@config.citation_validity_weight}
            name="config[citation_validity_weight]"
            phx-change="update_config"
            class="mt-1 block w-full"
          />
        </div>
      </div>
    </div>
    """
  end

  defp step_hyperparams(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-semibold mb-4">Step 5: Hyperparameters</h3>
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-gray-700">Learning Rate</label>
          <input
            type="number"
            step="0.00001"
            value={@config.learning_rate}
            name="config[learning_rate]"
            phx-change="update_config"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700">Epochs</label>
          <input
            type="number"
            value={@config.epochs}
            name="config[epochs]"
            phx-change="update_config"
            class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
          />
        </div>
      </div>
    </div>
    """
  end

  defp step_review(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-semibold mb-4">Step 6: Review</h3>
      <div class="bg-gray-50 rounded-lg p-4">
        <dl class="space-y-2 text-sm">
          <div class="flex justify-between">
            <dt class="text-gray-500">Dataset:</dt>
            <dd><%= @config.dataset_path || "Not specified" %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-500">Model:</dt>
            <dd><%= @config.model %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-500">LoRA Rank:</dt>
            <dd><%= @config.lora_rank %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-500">LoRA Alpha:</dt>
            <dd><%= @config.lora_alpha %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-500">LoRA Dropout:</dt>
            <dd><%= @config.lora_dropout %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-500">Citation Weight:</dt>
            <dd><%= @config.citation_validity_weight %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-500">Learning Rate:</dt>
            <dd><%= @config.learning_rate %></dd>
          </div>
          <div class="flex justify-between">
            <dt class="text-gray-500">Epochs:</dt>
            <dd><%= @config.epochs %></dd>
          </div>
          <%= if @job_status do %>
            <div class="flex justify-between">
              <dt class="text-gray-500">Crucible Job Status:</dt>
              <dd><%= @job_status %></dd>
            </div>
          <% end %>
        </dl>
      </div>
    </div>
    """
  end

  defp build_job_payload(config) do
    %{
      dataset_path: config.dataset_path,
      model: config.model,
      lora: %{
        rank: to_int(config.lora_rank),
        alpha: to_int(config.lora_alpha),
        dropout: to_float(config.lora_dropout),
        citation_validity_weight: to_float(config.citation_validity_weight)
      },
      training: %{
        learning_rate: to_float(config.learning_rate),
        epochs: to_int(config.epochs)
      },
      metadata: %{
        source: "cns_ui",
        requested_at: DateTime.utc_now()
      }
    }
  end

  defp normalize_config(config) do
    config
    |> Map.update(:lora_rank, nil, &to_int/1)
    |> Map.update(:lora_alpha, nil, &to_int/1)
    |> Map.update(:lora_dropout, nil, &to_float/1)
    |> Map.update(:citation_validity_weight, nil, &to_float/1)
    |> Map.update(:learning_rate, nil, &to_float/1)
    |> Map.update(:epochs, nil, &to_int/1)
  end

  defp to_int(value) when is_integer(value), do: value
  defp to_int(value) when is_binary(value), do: String.to_integer(value)
  defp to_int(value) when is_float(value), do: trunc(value)
  defp to_int(_), do: 0

  defp to_float(value) when is_float(value), do: value
  defp to_float(value) when is_integer(value), do: value * 1.0

  defp to_float(value) when is_binary(value) do
    case Float.parse(value) do
      {parsed, _} -> parsed
      _ -> 0.0
    end
  end

  defp to_float(_), do: 0.0

  defp maybe_update_job(job_id, update, socket) do
    cond do
      socket.assigns.job && socket.assigns.job["id"] == job_id ->
        progress =
          Map.get(update, :progress) || Map.get(update, "progress") ||
            socket.assigns.job_progress

        status =
          Map.get(update, :status) || Map.get(update, "status") || socket.assigns.job_status

        {:noreply,
         socket
         |> assign(:job_status, status)
         |> assign(:job_progress, to_float(progress))}

      true ->
        {:noreply, socket}
    end
  end

  defp format_error({:http_error, status, body}), do: "HTTP #{status}: #{inspect(body)}"
  defp format_error(reason), do: inspect(reason)
end
