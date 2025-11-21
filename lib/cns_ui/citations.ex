defmodule CnsUi.Citations do
  @moduledoc """
  Context for managing citations.
  """

  import Ecto.Query, warn: false
  alias CnsUi.Repo
  alias CnsUi.Citations.Citation

  @spec list_citations() :: [Citation.t()]
  def list_citations do
    Repo.all(from c in Citation, order_by: [desc: c.inserted_at])
  end

  @spec list_citations_for_sno(integer()) :: [Citation.t()]
  def list_citations_for_sno(sno_id) do
    from(c in Citation, where: c.sno_id == ^sno_id, order_by: [desc: c.validity_score])
    |> Repo.all()
  end

  @spec get_citation!(integer()) :: Citation.t()
  def get_citation!(id), do: Repo.get!(Citation, id)

  @spec create_citation(map()) :: {:ok, Citation.t()} | {:error, Ecto.Changeset.t()}
  def create_citation(attrs \\ %{}) do
    %Citation{}
    |> Citation.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_citation(Citation.t(), map()) :: {:ok, Citation.t()} | {:error, Ecto.Changeset.t()}
  def update_citation(%Citation{} = citation, attrs) do
    citation
    |> Citation.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_citation(Citation.t()) :: {:ok, Citation.t()} | {:error, Ecto.Changeset.t()}
  def delete_citation(%Citation{} = citation) do
    Repo.delete(citation)
  end

  @spec change_citation(Citation.t(), map()) :: Ecto.Changeset.t()
  def change_citation(%Citation{} = citation, attrs \\ %{}) do
    Citation.changeset(citation, attrs)
  end

  @spec average_validity_score() :: float() | nil
  def average_validity_score do
    from(c in Citation, select: avg(c.validity_score))
    |> Repo.one()
  end

  @spec citations_by_type() :: map()
  def citations_by_type do
    from(c in Citation, group_by: c.source_type, select: {c.source_type, count(c.id)})
    |> Repo.all()
    |> Map.new()
  end
end
