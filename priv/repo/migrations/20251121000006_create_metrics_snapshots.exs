defmodule CnsUi.Repo.Migrations.CreateMetricsSnapshots do
  use Ecto.Migration

  def change do
    create table(:metrics_snapshots) do
      add :entailment, :float
      add :chirality, :float
      add :fisher_rao, :float
      add :pass_rate, :float
      add :timestamp, :utc_datetime, null: false
      add :run_id, references(:training_runs, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:metrics_snapshots, [:run_id])
    create index(:metrics_snapshots, [:timestamp])
  end
end
