defmodule CnsUi.Metrics.MetricsSnapshot do
  @moduledoc """
  Schema for metrics snapshots from training runs.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          entailment: float() | nil,
          chirality: float() | nil,
          fisher_rao: float() | nil,
          pass_rate: float() | nil,
          timestamp: DateTime.t(),
          run_id: integer(),
          training_run: CnsUi.Training.TrainingRun.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "metrics_snapshots" do
    field :entailment, :float
    field :chirality, :float
    field :fisher_rao, :float
    field :pass_rate, :float
    field :timestamp, :utc_datetime

    belongs_to :training_run, CnsUi.Training.TrainingRun, foreign_key: :run_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [:entailment, :chirality, :fisher_rao, :pass_rate, :timestamp, :run_id])
    |> validate_required([:timestamp, :run_id])
    |> validate_number(:entailment, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_number(:chirality, greater_than_or_equal_to: -1.0, less_than_or_equal_to: 1.0)
    |> validate_number(:pass_rate, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> foreign_key_constraint(:run_id)
  end
end
