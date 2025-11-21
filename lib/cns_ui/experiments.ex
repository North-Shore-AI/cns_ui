defmodule CnsUi.Experiments do
  @moduledoc """
  Context for managing CNS experiments.
  """

  import Ecto.Query, warn: false
  alias CnsUi.Repo
  alias CnsUi.Experiments.Experiment

  @spec list_experiments() :: [Experiment.t()]
  def list_experiments do
    Repo.all(from e in Experiment, order_by: [desc: e.inserted_at])
  end

  @spec get_experiment!(integer()) :: Experiment.t()
  def get_experiment!(id), do: Repo.get!(Experiment, id)

  @spec get_experiment_with_runs!(integer()) :: Experiment.t()
  def get_experiment_with_runs!(id) do
    Experiment
    |> Repo.get!(id)
    |> Repo.preload(:training_runs)
  end

  @spec create_experiment(map()) :: {:ok, Experiment.t()} | {:error, Ecto.Changeset.t()}
  def create_experiment(attrs \\ %{}) do
    %Experiment{}
    |> Experiment.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_experiment(Experiment.t(), map()) ::
          {:ok, Experiment.t()} | {:error, Ecto.Changeset.t()}
  def update_experiment(%Experiment{} = experiment, attrs) do
    experiment
    |> Experiment.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_experiment(Experiment.t()) :: {:ok, Experiment.t()} | {:error, Ecto.Changeset.t()}
  def delete_experiment(%Experiment{} = experiment) do
    Repo.delete(experiment)
  end

  @spec change_experiment(Experiment.t(), map()) :: Ecto.Changeset.t()
  def change_experiment(%Experiment{} = experiment, attrs \\ %{}) do
    Experiment.changeset(experiment, attrs)
  end

  @spec active_experiments() :: [Experiment.t()]
  def active_experiments do
    from(e in Experiment, where: e.status == "running")
    |> Repo.all()
  end

  @spec count_by_status() :: map()
  def count_by_status do
    from(e in Experiment, group_by: e.status, select: {e.status, count(e.id)})
    |> Repo.all()
    |> Map.new()
  end
end
