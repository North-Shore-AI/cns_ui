defmodule CnsUi.SNOs.SNO do
  @moduledoc """
  Schema for Structured Narrative Objects (SNOs).

  SNOs represent claims with associated confidence scores, evidence,
  and provenance information in the dialectical reasoning system.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          claim: String.t(),
          confidence: float(),
          status: String.t(),
          evidence: map(),
          provenance: map(),
          metadata: map(),
          parent_id: integer() | nil,
          parent: t() | Ecto.Association.NotLoaded.t() | nil,
          children: [t()] | Ecto.Association.NotLoaded.t(),
          citations: [CnsUi.Citations.Citation.t()] | Ecto.Association.NotLoaded.t(),
          challenges: [CnsUi.Challenges.Challenge.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "snos" do
    field :claim, :string
    field :confidence, :float
    field :status, :string, default: "pending"
    field :evidence, :map, default: %{}
    field :provenance, :map, default: %{}
    field :metadata, :map, default: %{}

    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id
    has_many :citations, CnsUi.Citations.Citation
    has_many :challenges, CnsUi.Challenges.Challenge

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(sno, attrs) do
    sno
    |> cast(attrs, [:claim, :confidence, :status, :evidence, :provenance, :metadata, :parent_id])
    |> validate_required([:claim, :confidence])
    |> validate_number(:confidence, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_inclusion(:status, ["pending", "validated", "rejected", "synthesized"])
    |> foreign_key_constraint(:parent_id)
  end
end
