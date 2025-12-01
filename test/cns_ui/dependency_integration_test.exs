defmodule CnsUi.DependencyIntegrationTest do
  @moduledoc """
  Tests to verify proper dependency structure:
  - cns_ui depends on crucible_ui
  - cns_ui depends on cns
  - crucible_ui depends on crucible_telemetry
  """
  use ExUnit.Case, async: true

  describe "dependency structure" do
    test "crucible_ui is available as a dependency" do
      # Verify CrucibleUI application is loaded
      assert {:ok, _} = Application.ensure_all_started(:crucible_ui)

      # Verify key modules from crucible_ui are accessible
      assert Code.ensure_loaded?(CrucibleUI.Application)
    end

    test "cns is available as a dependency" do
      # Verify CNS application is loaded
      assert {:ok, _} = Application.ensure_all_started(:cns)

      # Verify key modules from cns are accessible
      assert Code.ensure_loaded?(CNS.Application)
    end

    test "crucible_telemetry is available through crucible_ui" do
      # Verify crucible_telemetry is accessible (transitive dependency)
      assert {:ok, _} = Application.ensure_all_started(:crucible_telemetry)
    end

    test "dependency chain is correct: cns_ui -> crucible_ui -> crucible_telemetry" do
      # Get the dependencies for cns_ui
      cns_ui_deps = Application.spec(:cns_ui, :applications) || []

      # cns_ui should depend on crucible_ui
      assert :crucible_ui in cns_ui_deps,
             "cns_ui should depend on crucible_ui, got: #{inspect(cns_ui_deps)}"

      # cns_ui should depend on cns
      assert :cns in cns_ui_deps,
             "cns_ui should depend on cns, got: #{inspect(cns_ui_deps)}"

      # Get the dependencies for crucible_ui
      crucible_ui_deps = Application.spec(:crucible_ui, :applications) || []

      # crucible_ui should depend on crucible_telemetry
      assert :crucible_telemetry in crucible_ui_deps,
             "crucible_ui should depend on crucible_telemetry, got: #{inspect(crucible_ui_deps)}"
    end
  end
end
