defmodule CnsUi.Repo.Migrations.CreateCitations do
  use Ecto.Migration

  def change do
    create table(:citations) do
      add :source_id, :string, null: false
      add :source_type, :string, null: false
      add :validity_score, :float
      add :grounding_score, :float
      add :sno_id, references(:snos, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:citations, [:sno_id])
    create index(:citations, [:source_type])
    create index(:citations, [:validity_score])
  end
end
