defmodule CnsUi.SNOsFixtures do
  @moduledoc """
  This module defines test helpers for creating SNO entities.
  """

  def valid_sno_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      claim: "Test claim #{System.unique_integer()}",
      confidence: 0.85,
      status: "pending",
      evidence: %{},
      provenance: %{},
      metadata: %{}
    })
  end

  def sno_fixture(attrs \\ %{}) do
    {:ok, sno} =
      attrs
      |> valid_sno_attributes()
      |> CnsUi.SNOs.create_sno()

    sno
  end
end
