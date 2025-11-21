defmodule CnsUi.Training do
  @moduledoc """
  Context for managing training runs.
  """

  import Ecto.Query, warn: false
  alias CnsUi.Repo
  alias CnsUi.Training.TrainingRun

  @spec list_training_runs() :: [TrainingRun.t()]
  def list_training_runs do
    Repo.all(from r in TrainingRun, order_by: [desc: r.inserted_at])
  end

  @spec list_training_runs_for_experiment(integer()) :: [TrainingRun.t()]
  def list_training_runs_for_experiment(experiment_id) do
    from(r in TrainingRun,
      where: r.experiment_id == ^experiment_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  @spec get_training_run!(integer()) :: TrainingRun.t()
  def get_training_run!(id), do: Repo.get!(TrainingRun, id)

  @spec get_training_run_with_snapshots!(integer()) :: TrainingRun.t()
  def get_training_run_with_snapshots!(id) do
    TrainingRun
    |> Repo.get!(id)
    |> Repo.preload(:metrics_snapshots)
  end

  @spec create_training_run(map()) :: {:ok, TrainingRun.t()} | {:error, Ecto.Changeset.t()}
  def create_training_run(attrs \\ %{}) do
    %TrainingRun{}
    |> TrainingRun.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_training_run(TrainingRun.t(), map()) ::
          {:ok, TrainingRun.t()} | {:error, Ecto.Changeset.t()}
  def update_training_run(%TrainingRun{} = run, attrs) do
    run
    |> TrainingRun.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_training_run(TrainingRun.t()) ::
          {:ok, TrainingRun.t()} | {:error, Ecto.Changeset.t()}
  def delete_training_run(%TrainingRun{} = run) do
    Repo.delete(run)
  end

  @spec change_training_run(TrainingRun.t(), map()) :: Ecto.Changeset.t()
  def change_training_run(%TrainingRun{} = run, attrs \\ %{}) do
    TrainingRun.changeset(run, attrs)
  end

  @spec active_runs() :: [TrainingRun.t()]
  def active_runs do
    from(r in TrainingRun, where: r.status == "running")
    |> Repo.all()
  end

  @spec add_checkpoint(TrainingRun.t(), String.t()) ::
          {:ok, TrainingRun.t()} | {:error, Ecto.Changeset.t()}
  def add_checkpoint(%TrainingRun{} = run, checkpoint_path) do
    update_training_run(run, %{checkpoints: run.checkpoints ++ [checkpoint_path]})
  end
end
