defmodule CnsUi.Repo.Migrations.CreateSnos do
  use Ecto.Migration

  def change do
    create table(:snos) do
      add :claim, :text, null: false
      add :confidence, :float, null: false
      add :status, :string, null: false, default: "pending"
      add :evidence, :map, default: %{}
      add :provenance, :map, default: %{}
      add :metadata, :map, default: %{}
      add :parent_id, references(:snos, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:snos, [:status])
    create index(:snos, [:confidence])
    create index(:snos, [:parent_id])
    create index(:snos, [:inserted_at])
  end
end
