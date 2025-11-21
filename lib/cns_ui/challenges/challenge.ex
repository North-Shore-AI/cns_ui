defmodule CnsUi.Challenges.Challenge do
  @moduledoc """
  Schema for challenges to SNOs from the Antagonist.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          challenge_type: String.t(),
          severity: String.t(),
          description: String.t(),
          resolution: String.t() | nil,
          sno_id: integer(),
          sno: CnsUi.SNOs.SNO.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "challenges" do
    field :challenge_type, :string
    field :severity, :string, default: "medium"
    field :description, :string
    field :resolution, :string

    belongs_to :sno, CnsUi.SNOs.SNO

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(challenge, attrs) do
    challenge
    |> cast(attrs, [:challenge_type, :severity, :description, :resolution, :sno_id])
    |> validate_required([:challenge_type, :description, :sno_id])
    |> validate_inclusion(:severity, ["low", "medium", "high", "critical"])
    |> validate_inclusion(:challenge_type, [
      "contradiction",
      "insufficient_evidence",
      "logical_fallacy",
      "bias",
      "other"
    ])
    |> foreign_key_constraint(:sno_id)
  end
end
