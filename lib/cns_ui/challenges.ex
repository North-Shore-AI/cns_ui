defmodule CnsUi.Challenges do
  @moduledoc """
  Context for managing challenges.
  """

  import Ecto.Query, warn: false
  alias CnsUi.Repo
  alias CnsUi.Challenges.Challenge

  @spec list_challenges() :: [Challenge.t()]
  def list_challenges do
    Repo.all(from c in Challenge, order_by: [desc: c.inserted_at])
  end

  @spec list_challenges_for_sno(integer()) :: [Challenge.t()]
  def list_challenges_for_sno(sno_id) do
    from(c in Challenge, where: c.sno_id == ^sno_id, order_by: [desc: c.severity])
    |> Repo.all()
  end

  @spec get_challenge!(integer()) :: Challenge.t()
  def get_challenge!(id), do: Repo.get!(Challenge, id)

  @spec create_challenge(map()) :: {:ok, Challenge.t()} | {:error, Ecto.Changeset.t()}
  def create_challenge(attrs \\ %{}) do
    %Challenge{}
    |> Challenge.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_challenge(Challenge.t(), map()) ::
          {:ok, Challenge.t()} | {:error, Ecto.Changeset.t()}
  def update_challenge(%Challenge{} = challenge, attrs) do
    challenge
    |> Challenge.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_challenge(Challenge.t()) :: {:ok, Challenge.t()} | {:error, Ecto.Changeset.t()}
  def delete_challenge(%Challenge{} = challenge) do
    Repo.delete(challenge)
  end

  @spec change_challenge(Challenge.t(), map()) :: Ecto.Changeset.t()
  def change_challenge(%Challenge{} = challenge, attrs \\ %{}) do
    Challenge.changeset(challenge, attrs)
  end

  @spec unresolved_challenges() :: [Challenge.t()]
  def unresolved_challenges do
    from(c in Challenge, where: is_nil(c.resolution), order_by: [desc: c.severity])
    |> Repo.all()
  end

  @spec resolve_challenge(Challenge.t(), String.t()) ::
          {:ok, Challenge.t()} | {:error, Ecto.Changeset.t()}
  def resolve_challenge(%Challenge{} = challenge, resolution) do
    update_challenge(challenge, %{resolution: resolution})
  end

  @spec count_by_severity() :: map()
  def count_by_severity do
    from(c in Challenge, group_by: c.severity, select: {c.severity, count(c.id)})
    |> Repo.all()
    |> Map.new()
  end
end
