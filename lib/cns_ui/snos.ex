defmodule CnsUi.SNOs do
  @moduledoc """
  Context for managing Structured Narrative Objects (SNOs).

  Provides CRUD operations and queries for SNOs in the dialectical reasoning system.
  """

  import Ecto.Query, warn: false
  alias CnsUi.Repo
  alias CnsUi.SNOs.SNO

  @doc """
  Returns all SNOs.
  """
  @spec list_snos() :: [SNO.t()]
  def list_snos do
    Repo.all(from s in SNO, order_by: [desc: s.inserted_at])
  end

  @doc """
  Returns SNOs matching the given filters.
  """
  @spec list_snos(keyword()) :: [SNO.t()]
  def list_snos(filters) do
    SNO
    |> apply_filters(filters)
    |> Repo.all()
  end

  @doc """
  Gets a single SNO.

  Raises `Ecto.NoResultsError` if the SNO does not exist.
  """
  @spec get_sno!(integer()) :: SNO.t()
  def get_sno!(id), do: Repo.get!(SNO, id)

  @doc """
  Gets a single SNO with preloaded associations.
  """
  @spec get_sno_with_associations!(integer()) :: SNO.t()
  def get_sno_with_associations!(id) do
    SNO
    |> Repo.get!(id)
    |> Repo.preload([:parent, :children, :citations, :challenges])
  end

  @doc """
  Creates a SNO.
  """
  @spec create_sno(map()) :: {:ok, SNO.t()} | {:error, Ecto.Changeset.t()}
  def create_sno(attrs \\ %{}) do
    %SNO{}
    |> SNO.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a SNO.
  """
  @spec update_sno(SNO.t(), map()) :: {:ok, SNO.t()} | {:error, Ecto.Changeset.t()}
  def update_sno(%SNO{} = sno, attrs) do
    sno
    |> SNO.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a SNO.
  """
  @spec delete_sno(SNO.t()) :: {:ok, SNO.t()} | {:error, Ecto.Changeset.t()}
  def delete_sno(%SNO{} = sno) do
    Repo.delete(sno)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking SNO changes.
  """
  @spec change_sno(SNO.t(), map()) :: Ecto.Changeset.t()
  def change_sno(%SNO{} = sno, attrs \\ %{}) do
    SNO.changeset(sno, attrs)
  end

  @doc """
  Returns SNOs with confidence above the threshold.
  """
  @spec high_confidence_snos(float()) :: [SNO.t()]
  def high_confidence_snos(threshold \\ 0.8) do
    from(s in SNO, where: s.confidence >= ^threshold, order_by: [desc: s.confidence])
    |> Repo.all()
  end

  @doc """
  Returns recent SNOs.
  """
  @spec recent_snos(integer()) :: [SNO.t()]
  def recent_snos(limit \\ 10) do
    from(s in SNO, order_by: [desc: s.inserted_at], limit: ^limit)
    |> Repo.all()
  end

  @doc """
  Counts SNOs by status.
  """
  @spec count_by_status() :: map()
  def count_by_status do
    from(s in SNO, group_by: s.status, select: {s.status, count(s.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Returns the synthesis chain for a SNO.
  """
  @spec get_synthesis_chain(integer()) :: [SNO.t()]
  def get_synthesis_chain(sno_id) do
    sno = get_sno!(sno_id)
    build_chain(sno, [sno])
  end

  defp build_chain(%SNO{parent_id: nil}, chain), do: Enum.reverse(chain)

  defp build_chain(%SNO{parent_id: parent_id}, chain) do
    parent = get_sno!(parent_id)
    build_chain(parent, [parent | chain])
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, q -> where(q, [s], s.status == ^status)
      {:min_confidence, min}, q -> where(q, [s], s.confidence >= ^min)
      {:max_confidence, max}, q -> where(q, [s], s.confidence <= ^max)
      {:search, term}, q -> where(q, [s], ilike(s.claim, ^"%#{term}%"))
      {:limit, limit}, q -> limit(q, ^limit)
      {:order_by, field}, q -> order_by(q, [s], desc: ^field)
      _, q -> q
    end)
  end
end
