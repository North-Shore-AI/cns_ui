defmodule CnsUi.ExperimentBackend do
  @moduledoc """
  CNS-specific backend implementation for Crucible UI experiment features.

  Provides experiment and training run operations for CNS dialectical reasoning
  experiments, integrating with the existing `CnsUi.Experiments` and `CnsUi.Training`
  contexts to deliver a unified experiment management interface.

  ## Integration Architecture

  This backend acts as an adapter between Crucible UI's composable experiment
  dashboard and CNS UI's existing experiment management contexts:

  ```
  Crucible UI (mounted at /crucible/experiments)
       ↓
  CnsUi.ExperimentBackend (this module)
       ↓
  CnsUi.Experiments + CnsUi.Training (existing contexts)
  ```

  ## CNS Experiment Workflow

  1. **Experiment Creation** - Define dialectical reasoning experiments with
     dataset selection (SciFact, FEVER), model configuration (Proposer, Antagonist,
     Synthesizer agents), and quality thresholds (β₁, chirality, entailment).

  2. **Training Runs** - Submit training jobs to Crucible Framework via
     `CnsUi.CrucibleClient`, tracking LoRA adapter training for claim extraction,
     contradiction detection, and synthesis.

  3. **Real-time Monitoring** - Subscribe to PubSub updates from Crucible,
     streaming telemetry events (loss curves, checkpoint creation, metric snapshots)
     to LiveView dashboards.

  4. **Result Analysis** - Aggregate statistics across runs, compare model
     performance, export results for publication.

  ## Telemetry Events

  This backend emits structured telemetry for monitoring:

  - `[:cns_ui, :experiment, :listed]` - Experiment list queries
  - `[:cns_ui, :experiment, :fetched]` - Single experiment retrieval
  - `[:cns_ui, :experiment, :created]` - New experiment creation
  - `[:cns_ui, :experiment, :updated]` - Experiment status updates
  - `[:cns_ui, :run, :listed]` - Run list queries
  - `[:cns_ui, :run, :fetched]` - Single run retrieval
  - `[:cns_ui, :stats, :computed]` - Statistics computation

  ## PubSub Topics

  Custom PubSub topic naming for CNS-specific routing:

  - `cns:experiment:{id}` - Experiment-level updates
  - `cns:run:{id}` - Run-level updates (loss, metrics, checkpoints)

  ## Error Handling

  All callbacks return structured errors:

  - `{:error, :not_found}` - Resource doesn't exist
  - `{:error, changeset}` - Validation errors with details
  - `{:error, exception}` - Unexpected errors (logged)

  ## Examples

      # List all CNS experiments
      {:ok, experiments} = CnsUi.ExperimentBackend.list_experiments()

      # Get experiment with training runs
      {:ok, exp} = CnsUi.ExperimentBackend.get_experiment_with_associations(123)

      # Create new experiment
      {:ok, exp} = CnsUi.ExperimentBackend.create_experiment(%{
        name: "SciFact Proposer v2",
        description: "LoRA claim extraction with entailment loss",
        config: %{dataset: "scifact", model: "llama-3.1-8b"}
      })

      # Get system-wide statistics
      {:ok, stats} = CnsUi.ExperimentBackend.get_system_statistics()
      # => %{experiments: %{total: 42, running: 3}, runs: %{total: 156, active: 5}}
  """

  @behaviour Crucible.UI.Backend

  require Logger

  alias CnsUi.Experiments
  alias CnsUi.Training

  @doc """
  Lists all CNS experiments with optional filtering.

  ## Parameters

  - `opts` - Keyword list with optional filters:
    - `:status` - Filter by experiment status ("pending", "running", "completed", "failed")
    - `:limit` - Maximum number of experiments to return

  ## Returns

  - `{:ok, [%Experiment{}]}` - List of experiments
  - `{:error, exception}` - Unexpected error

  ## Examples

      iex> list_experiments(status: "running", limit: 10)
      {:ok, [%Experiment{status: "running", ...}, ...]}
  """
  @impl true
  def list_experiments(opts \\ []) do
    Logger.debug("Listing experiments with opts: #{inspect(opts)}")

    experiments =
      case Keyword.get(opts, :status) do
        nil ->
          Experiments.list_experiments()

        status ->
          Experiments.list_experiments()
          |> Enum.filter(&(&1.status == status))
      end

    experiments =
      case Keyword.get(opts, :limit) do
        nil -> experiments
        limit -> Enum.take(experiments, limit)
      end

    # Emit telemetry
    :telemetry.execute(
      [:cns_ui, :experiment, :listed],
      %{count: length(experiments)},
      %{filters: opts}
    )

    {:ok, experiments}
  rescue
    exception ->
      Logger.error("Error listing experiments: #{inspect(exception)}")
      {:error, exception}
  end

  @doc """
  Retrieves a single experiment by ID.

  ## Parameters

  - `id` - Experiment identifier

  ## Returns

  - `{:ok, %Experiment{}}` - Found experiment
  - `{:error, :not_found}` - Experiment doesn't exist

  ## Examples

      iex> get_experiment(123)
      {:ok, %Experiment{id: 123, name: "SciFact Proposer", ...}}
  """
  @impl true
  def get_experiment(id) do
    Logger.debug("Fetching experiment id=#{id}")

    result =
      case Experiments.get_experiment!(id) do
        nil -> {:error, :not_found}
        experiment -> {:ok, experiment}
      end

    :telemetry.execute(
      [:cns_ui, :experiment, :fetched],
      %{count: 1},
      %{id: id, result: elem(result, 0)}
    )

    result
  rescue
    Ecto.NoResultsError ->
      {:error, :not_found}

    exception ->
      Logger.error("Error fetching experiment #{id}: #{inspect(exception)}")
      {:error, exception}
  end

  @doc """
  Retrieves an experiment with all associated training runs preloaded.

  ## Parameters

  - `id` - Experiment identifier

  ## Returns

  - `{:ok, %Experiment{training_runs: [%TrainingRun{}, ...]}}` - Experiment with runs
  - `{:error, :not_found}` - Experiment doesn't exist

  ## Examples

      iex> get_experiment_with_associations(123)
      {:ok, %Experiment{id: 123, training_runs: [...]}}
  """
  @impl true
  def get_experiment_with_associations(id) do
    Logger.debug("Fetching experiment with associations id=#{id}")

    case Experiments.get_experiment_with_runs!(id) do
      nil -> {:error, :not_found}
      experiment -> {:ok, experiment}
    end
  rescue
    Ecto.NoResultsError ->
      {:error, :not_found}

    exception ->
      Logger.error("Error fetching experiment with associations #{id}: #{inspect(exception)}")
      {:error, exception}
  end

  @doc """
  Creates a new CNS experiment.

  ## Parameters

  - `attrs` - Map with experiment attributes (name, description, config, etc.)

  ## Returns

  - `{:ok, %Experiment{}}` - Created experiment
  - `{:error, changeset}` - Validation errors

  ## Examples

      iex> create_experiment(%{name: "Test", config: %{}})
      {:ok, %Experiment{id: 456, ...}}
  """
  @impl true
  def create_experiment(attrs) do
    Logger.info("Creating experiment with attrs: #{inspect(attrs)}")

    result = Experiments.create_experiment(attrs)

    :telemetry.execute(
      [:cns_ui, :experiment, :created],
      %{count: 1},
      %{result: elem(result, 0)}
    )

    result
  end

  @doc """
  Updates an existing experiment.

  ## Parameters

  - `id` - Experiment identifier
  - `attrs` - Map with attributes to update

  ## Returns

  - `{:ok, %Experiment{}}` - Updated experiment
  - `{:error, :not_found}` - Experiment doesn't exist
  - `{:error, changeset}` - Validation errors

  ## Examples

      iex> update_experiment(123, %{status: "completed"})
      {:ok, %Experiment{id: 123, status: "completed", ...}}
  """
  @impl true
  def update_experiment(id, attrs) do
    Logger.info("Updating experiment id=#{id} with attrs: #{inspect(attrs)}")

    result =
      case get_experiment(id) do
        {:ok, experiment} ->
          Experiments.update_experiment(experiment, attrs)

        {:error, _} = error ->
          error
      end

    :telemetry.execute(
      [:cns_ui, :experiment, :updated],
      %{count: 1},
      %{id: id, result: elem(result, 0)}
    )

    result
  end

  @doc """
  Deletes an experiment and all associated runs.

  ## Parameters

  - `id` - Experiment identifier

  ## Returns

  - `{:ok, %Experiment{}}` - Deleted experiment
  - `{:error, :not_found}` - Experiment doesn't exist
  - `{:error, changeset}` - Deletion constraints violated

  ## Examples

      iex> delete_experiment(123)
      {:ok, %Experiment{id: 123, ...}}
  """
  @impl true
  def delete_experiment(id) do
    Logger.warning("Deleting experiment id=#{id}")

    case get_experiment(id) do
      {:ok, experiment} ->
        Experiments.delete_experiment(experiment)

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Starts an experiment by updating its status to "running".

  ## Parameters

  - `id` - Experiment identifier

  ## Returns

  - `{:ok, %Experiment{status: "running"}}` - Started experiment
  - `{:error, :not_found}` - Experiment doesn't exist

  ## Examples

      iex> start_experiment(123)
      {:ok, %Experiment{id: 123, status: "running", ...}}
  """
  @impl true
  def start_experiment(id) do
    Logger.info("Starting experiment id=#{id}")
    update_experiment(id, %{status: "running"})
  end

  @doc """
  Completes an experiment by updating its status to "completed".

  ## Parameters

  - `id` - Experiment identifier

  ## Returns

  - `{:ok, %Experiment{status: "completed"}}` - Completed experiment
  - `{:error, :not_found}` - Experiment doesn't exist

  ## Examples

      iex> complete_experiment(123)
      {:ok, %Experiment{id: 123, status: "completed", ...}}
  """
  @impl true
  def complete_experiment(id) do
    Logger.info("Completing experiment id=#{id}")
    update_experiment(id, %{status: "completed"})
  end

  @doc """
  Lists all training runs for an experiment.

  ## Parameters

  - `experiment_id` - Experiment identifier
  - `opts` - Keyword list with optional filters:
    - `:status` - Filter by run status
    - `:limit` - Maximum number of runs to return

  ## Returns

  - `{:ok, [%TrainingRun{}]}` - List of training runs
  - `{:error, exception}` - Unexpected error

  ## Examples

      iex> list_runs(123, status: "completed", limit: 5)
      {:ok, [%TrainingRun{status: "completed", ...}, ...]}
  """
  @impl true
  def list_runs(experiment_id, opts \\ []) do
    Logger.debug("Listing runs for experiment=#{experiment_id}")

    runs = Training.list_training_runs_for_experiment(experiment_id)

    runs =
      case Keyword.get(opts, :status) do
        nil -> runs
        status -> Enum.filter(runs, &(&1.status == status))
      end

    runs =
      case Keyword.get(opts, :limit) do
        nil -> runs
        limit -> Enum.take(runs, limit)
      end

    :telemetry.execute(
      [:cns_ui, :run, :listed],
      %{count: length(runs)},
      %{experiment_id: experiment_id, filters: opts}
    )

    {:ok, runs}
  rescue
    exception ->
      Logger.error("Error listing runs for experiment #{experiment_id}: #{inspect(exception)}")
      {:error, exception}
  end

  @doc """
  Retrieves a single training run with snapshots preloaded.

  ## Parameters

  - `id` - Training run identifier

  ## Returns

  - `{:ok, %TrainingRun{snapshots: [...]}}` - Run with snapshots
  - `{:error, :not_found}` - Run doesn't exist

  ## Examples

      iex> get_run(456)
      {:ok, %TrainingRun{id: 456, snapshots: [...], ...}}
  """
  @impl true
  def get_run(id) do
    Logger.debug("Fetching run id=#{id}")

    result =
      case Training.get_training_run_with_snapshots!(id) do
        nil -> {:error, :not_found}
        run -> {:ok, run}
      end

    :telemetry.execute(
      [:cns_ui, :run, :fetched],
      %{count: 1},
      %{id: id, result: elem(result, 0)}
    )

    result
  rescue
    Ecto.NoResultsError ->
      {:error, :not_found}

    exception ->
      Logger.error("Error fetching run #{id}: #{inspect(exception)}")
      {:error, exception}
  end

  @doc """
  Starts a training run by updating its status to "running".

  ## Parameters

  - `id` - Training run identifier

  ## Returns

  - `{:ok, %TrainingRun{status: "running"}}` - Started run
  - `{:error, :not_found}` - Run doesn't exist

  ## Examples

      iex> start_run(456)
      {:ok, %TrainingRun{id: 456, status: "running", ...}}
  """
  @impl true
  def start_run(id) do
    Logger.info("Starting run id=#{id}")

    case get_run(id) do
      {:ok, run} ->
        Training.update_training_run(run, %{status: "running"})

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Completes a training run by updating its status to "completed".

  ## Parameters

  - `id` - Training run identifier

  ## Returns

  - `{:ok, %TrainingRun{status: "completed"}}` - Completed run
  - `{:error, :not_found}` - Run doesn't exist

  ## Examples

      iex> complete_run(456)
      {:ok, %TrainingRun{id: 456, status: "completed", ...}}
  """
  @impl true
  def complete_run(id) do
    Logger.info("Completing run id=#{id}")

    case get_run(id) do
      {:ok, run} ->
        Training.update_training_run(run, %{status: "completed"})

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Lists telemetry events for a training run.

  ## Parameters

  - `run_id` - Training run identifier
  - `opts` - Keyword list with options:
    - `:limit` - Maximum events to return (default: 100)

  ## Returns

  - `{:ok, [event_map]}` - List of telemetry events
  - `{:error, reason}` - Error retrieving events

  ## Note

  Currently returns empty list. Future implementation will integrate
  with CnsUi.Metrics or dedicated telemetry_events table.

  ## Examples

      iex> list_telemetry_events(456, limit: 50)
      {:ok, []}
  """
  @impl true
  def list_telemetry_events(_run_id, opts \\ []) do
    # For CNS, telemetry events are stored in metrics
    # This is a simplified implementation
    # Future: implement proper telemetry event storage and retrieval
    _limit = Keyword.get(opts, :limit, 100)

    # Future implementation:
    # 1. Create telemetry_events table with run_id foreign key
    # 2. Store events from PubSub updates
    # 3. Query here with filters (event_type, time_range, etc.)
    # 4. Return structured events for timeline visualization

    Logger.debug("Telemetry event listing not yet implemented")
    {:ok, []}
  end

  @doc """
  Retrieves statistics for a training run or experiment.

  ## Parameters

  - `id` - Run or experiment identifier

  ## Returns

  - `{:ok, stats_map}` - Statistics with counts, metrics, durations
  - `{:error, :not_found}` - Resource doesn't exist

  ## Examples

      iex> get_statistics(456)
      {:ok, %{run_id: 456, status: "completed", duration: 3600, ...}}

      iex> get_statistics(123)
      {:ok, %{experiment_id: 123, total_runs: 5, completed_runs: 3, ...}}
  """
  @impl true
  def get_statistics(id) do
    Logger.debug("Computing statistics for id=#{id}")

    result =
      case get_run_statistics(id) do
        {:ok, stats} ->
          {:ok, stats}

        {:error, :not_found} ->
          get_experiment_statistics(id)

        error ->
          error
      end

    :telemetry.execute(
      [:cns_ui, :stats, :computed],
      %{count: 1},
      %{id: id, result: elem(result, 0)}
    )

    result
  end

  @doc """
  Retrieves system-wide statistics across all experiments and runs.

  ## Returns

  - `{:ok, stats_map}` - Aggregate statistics with counts by status
  - `{:error, exception}` - Error computing statistics

  ## Examples

      iex> get_system_statistics()
      {:ok, %{
        experiments: %{total: 42, running: 3, completed: 35, failed: 4},
        runs: %{total: 156, active: 5},
        last_updated: ~U[2024-11-21 12:00:00Z]
      }}
  """
  @impl true
  def get_system_statistics do
    Logger.debug("Computing system-wide statistics")

    experiment_counts = Experiments.count_by_status()

    all_runs = Training.list_training_runs()
    total_runs = length(all_runs)
    active_runs = length(Training.active_runs())

    stats = %{
      experiments: %{
        total: Enum.sum(Map.values(experiment_counts)),
        pending: Map.get(experiment_counts, "pending", 0),
        running: Map.get(experiment_counts, "running", 0),
        completed: Map.get(experiment_counts, "completed", 0),
        failed: Map.get(experiment_counts, "failed", 0)
      },
      runs: %{
        total: total_runs,
        active: active_runs
      },
      last_updated: DateTime.utc_now()
    }

    :telemetry.execute(
      [:cns_ui, :stats, :system],
      %{count: 1},
      %{experiments: stats.experiments.total, runs: stats.runs.total}
    )

    {:ok, stats}
  rescue
    exception ->
      Logger.error("Error computing system statistics: #{inspect(exception)}")
      {:error, exception}
  end

  @doc """
  Returns custom PubSub topic names for CNS resources.

  ## Parameters

  - `resource` - Resource type (`:experiment`, `:run`, etc.)
  - `id` - Resource identifier

  ## Returns

  String topic name in format "cns:{resource}:{id}"

  ## Examples

      iex> pubsub_topic(:experiment, 123)
      "cns:experiment:123"

      iex> pubsub_topic(:run, 456)
      "cns:run:456"
  """
  @impl true
  def pubsub_topic(:experiment, id) do
    "cns:experiment:#{id}"
  end

  def pubsub_topic(:run, id) do
    "cns:run:#{id}"
  end

  def pubsub_topic(resource, id) do
    "cns:#{resource}:#{id}"
  end

  # Private helper functions

  # Computes statistics for a single training run.
  # Includes duration, metrics, checkpoint count.
  defp get_run_statistics(run_id) do
    case Training.get_training_run!(run_id) do
      nil ->
        {:error, :not_found}

      run ->
        # Handle optional started_at/completed_at fields
        started_at = Map.get(run, :started_at)
        completed_at = Map.get(run, :completed_at)

        stats = %{
          run_id: run.id,
          status: run.status,
          started_at: started_at,
          completed_at: completed_at,
          duration: calculate_duration(started_at, completed_at),
          metrics: run.metrics || %{},
          checkpoints: length(run.checkpoints || [])
        }

        {:ok, stats}
    end
  rescue
    Ecto.NoResultsError ->
      {:error, :not_found}

    exception ->
      Logger.error("Error computing run statistics for #{run_id}: #{inspect(exception)}")
      {:error, exception}
  end

  # Computes statistics for an experiment across all its runs.
  # Aggregates run counts by status, timestamps.
  defp get_experiment_statistics(experiment_id) do
    case Experiments.get_experiment_with_runs!(experiment_id) do
      nil ->
        {:error, :not_found}

      experiment ->
        runs = experiment.training_runs || []

        stats = %{
          experiment_id: experiment.id,
          status: experiment.status,
          total_runs: length(runs),
          completed_runs: Enum.count(runs, &(&1.status == "completed")),
          running_runs: Enum.count(runs, &(&1.status == "running")),
          failed_runs: Enum.count(runs, &(&1.status == "failed")),
          created_at: experiment.inserted_at,
          updated_at: experiment.updated_at
        }

        {:ok, stats}
    end
  rescue
    Ecto.NoResultsError ->
      {:error, :not_found}

    exception ->
      Logger.error(
        "Error computing experiment statistics for #{experiment_id}: #{inspect(exception)}"
      )

      {:error, exception}
  end

  # Calculates duration between two timestamps in seconds.
  # Returns nil if either timestamp is missing.
  defp calculate_duration(nil, _), do: nil
  defp calculate_duration(_, nil), do: nil

  defp calculate_duration(started_at, completed_at) do
    DateTime.diff(completed_at, started_at, :second)
  end
end
