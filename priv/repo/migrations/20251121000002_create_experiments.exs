defmodule CnsUi.Repo.Migrations.CreateExperiments do
  use Ecto.Migration

  def change do
    create table(:experiments) do
      add :name, :string, null: false
      add :description, :text
      add :status, :string, null: false, default: "pending"
      add :config, :map, default: %{}
      add :dataset_path, :string

      timestamps(type: :utc_datetime)
    end

    create index(:experiments, [:status])
    create unique_index(:experiments, [:name])
  end
end
