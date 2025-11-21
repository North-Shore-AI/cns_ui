defmodule CnsUi.ExperimentsFixtures do
  @moduledoc """
  This module defines test helpers for creating experiment entities.
  """

  def valid_experiment_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test experiment #{System.unique_integer()}",
      description: "Test description",
      status: "pending",
      config: %{},
      dataset_path: "/path/to/dataset"
    })
  end

  def experiment_fixture(attrs \\ %{}) do
    {:ok, experiment} =
      attrs
      |> valid_experiment_attributes()
      |> CnsUi.Experiments.create_experiment()

    experiment
  end
end
