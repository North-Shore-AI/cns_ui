defmodule CnsUi.Metrics do
  @moduledoc """
  Context for managing metrics collection and analysis.
  """

  import Ecto.Query, warn: false
  alias CnsUi.Repo
  alias CnsUi.Metrics.MetricsSnapshot

  @spec list_metrics_snapshots() :: [MetricsSnapshot.t()]
  def list_metrics_snapshots do
    Repo.all(from m in MetricsSnapshot, order_by: [desc: m.timestamp])
  end

  @spec list_snapshots_for_run(integer()) :: [MetricsSnapshot.t()]
  def list_snapshots_for_run(run_id) do
    from(m in MetricsSnapshot, where: m.run_id == ^run_id, order_by: [asc: m.timestamp])
    |> Repo.all()
  end

  @spec get_metrics_snapshot!(integer()) :: MetricsSnapshot.t()
  def get_metrics_snapshot!(id), do: Repo.get!(MetricsSnapshot, id)

  @spec create_metrics_snapshot(map()) ::
          {:ok, MetricsSnapshot.t()} | {:error, Ecto.Changeset.t()}
  def create_metrics_snapshot(attrs \\ %{}) do
    %MetricsSnapshot{}
    |> MetricsSnapshot.changeset(attrs)
    |> Repo.insert()
  end

  @spec delete_metrics_snapshot(MetricsSnapshot.t()) ::
          {:ok, MetricsSnapshot.t()} | {:error, Ecto.Changeset.t()}
  def delete_metrics_snapshot(%MetricsSnapshot{} = snapshot) do
    Repo.delete(snapshot)
  end

  @spec change_metrics_snapshot(MetricsSnapshot.t(), map()) :: Ecto.Changeset.t()
  def change_metrics_snapshot(%MetricsSnapshot{} = snapshot, attrs \\ %{}) do
    MetricsSnapshot.changeset(snapshot, attrs)
  end

  @spec latest_snapshot_for_run(integer()) :: MetricsSnapshot.t() | nil
  def latest_snapshot_for_run(run_id) do
    from(m in MetricsSnapshot,
      where: m.run_id == ^run_id,
      order_by: [desc: m.timestamp],
      limit: 1
    )
    |> Repo.one()
  end

  @spec average_metrics() :: map()
  def average_metrics do
    from(m in MetricsSnapshot,
      select: %{
        avg_entailment: avg(m.entailment),
        avg_chirality: avg(m.chirality),
        avg_fisher_rao: avg(m.fisher_rao),
        avg_pass_rate: avg(m.pass_rate)
      }
    )
    |> Repo.one()
  end

  @spec metrics_trend(integer(), integer()) :: [MetricsSnapshot.t()]
  def metrics_trend(run_id, limit \\ 100) do
    from(m in MetricsSnapshot,
      where: m.run_id == ^run_id,
      order_by: [asc: m.timestamp],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Records a new metrics snapshot for a training run.
  """
  @spec record_snapshot(integer(), map()) ::
          {:ok, MetricsSnapshot.t()} | {:error, Ecto.Changeset.t()}
  def record_snapshot(run_id, metrics) do
    attrs = Map.merge(metrics, %{run_id: run_id, timestamp: DateTime.utc_now()})
    create_metrics_snapshot(attrs)
  end
end
