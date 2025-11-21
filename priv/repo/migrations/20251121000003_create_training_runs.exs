defmodule CnsUi.Repo.Migrations.CreateTrainingRuns do
  use Ecto.Migration

  def change do
    create table(:training_runs) do
      add :status, :string, null: false, default: "pending"
      add :metrics, :map, default: %{}
      add :checkpoints, {:array, :string}, default: []
      add :lora_config, :map, default: %{}
      add :experiment_id, references(:experiments, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:training_runs, [:experiment_id])
    create index(:training_runs, [:status])
  end
end
