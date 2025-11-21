defmodule CnsUi.Citations.Citation do
  @moduledoc """
  Schema for citations linking SNOs to sources.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          source_id: String.t(),
          source_type: String.t(),
          validity_score: float() | nil,
          grounding_score: float() | nil,
          sno_id: integer(),
          sno: CnsUi.SNOs.SNO.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "citations" do
    field :source_id, :string
    field :source_type, :string
    field :validity_score, :float
    field :grounding_score, :float

    belongs_to :sno, CnsUi.SNOs.SNO

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(citation, attrs) do
    citation
    |> cast(attrs, [:source_id, :source_type, :validity_score, :grounding_score, :sno_id])
    |> validate_required([:source_id, :source_type, :sno_id])
    |> validate_number(:validity_score, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_number(:grounding_score,
      greater_than_or_equal_to: 0.0,
      less_than_or_equal_to: 1.0
    )
    |> foreign_key_constraint(:sno_id)
  end
end
