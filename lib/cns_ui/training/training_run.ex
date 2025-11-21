defmodule CnsUi.Training.TrainingRun do
  @moduledoc """
  Schema for training runs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          status: String.t(),
          metrics: map(),
          checkpoints: [String.t()],
          lora_config: map(),
          experiment_id: integer(),
          experiment: CnsUi.Experiments.Experiment.t() | Ecto.Association.NotLoaded.t(),
          metrics_snapshots: [CnsUi.Metrics.MetricsSnapshot.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "training_runs" do
    field :status, :string, default: "pending"
    field :metrics, :map, default: %{}
    field :checkpoints, {:array, :string}, default: []
    field :lora_config, :map, default: %{}

    belongs_to :experiment, CnsUi.Experiments.Experiment
    has_many :metrics_snapshots, CnsUi.Metrics.MetricsSnapshot, foreign_key: :run_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(training_run, attrs) do
    training_run
    |> cast(attrs, [:status, :metrics, :checkpoints, :lora_config, :experiment_id])
    |> validate_required([:experiment_id])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed", "cancelled"])
    |> foreign_key_constraint(:experiment_id)
  end
end
