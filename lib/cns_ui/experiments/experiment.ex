defmodule CnsUi.Experiments.Experiment do
  @moduledoc """
  Schema for CNS experiments.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t(),
          description: String.t() | nil,
          status: String.t(),
          config: map(),
          dataset_path: String.t() | nil,
          training_runs: [CnsUi.Training.TrainingRun.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "experiments" do
    field :name, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :config, :map, default: %{}
    field :dataset_path, :string

    has_many :training_runs, CnsUi.Training.TrainingRun

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(experiment, attrs) do
    experiment
    |> cast(attrs, [:name, :description, :status, :config, :dataset_path])
    |> validate_required([:name])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed", "cancelled"])
    |> unique_constraint(:name)
  end
end
