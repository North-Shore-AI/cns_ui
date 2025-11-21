defmodule CnsUi.Repo.Migrations.CreateChallenges do
  use Ecto.Migration

  def change do
    create table(:challenges) do
      add :challenge_type, :string, null: false
      add :severity, :string, null: false, default: "medium"
      add :description, :text, null: false
      add :resolution, :text
      add :sno_id, references(:snos, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:challenges, [:sno_id])
    create index(:challenges, [:challenge_type])
    create index(:challenges, [:severity])
  end
end
