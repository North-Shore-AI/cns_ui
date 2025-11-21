defmodule CnsUi do
  @moduledoc """
  CNS UI - Phoenix LiveView interface for CNS dialectical reasoning experiments.

  This module provides the main entry point for the CNS UI application.
  """

  @doc """
  Returns the current version of CNS UI.
  """
  @spec version() :: String.t()
  def version, do: "0.1.0"
end
