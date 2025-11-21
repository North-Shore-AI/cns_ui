defmodule CnsUiWeb.DashboardLiveTest do
  use CnsUiWeb.ConnCase

  import Phoenix.LiveViewTest
  import CnsUi.SNOsFixtures
  import CnsUi.ExperimentsFixtures

  describe "Dashboard" do
    test "renders dashboard page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "CNS Dashboard"
      assert html =~ "Overview of dialectical reasoning system"
    end

    test "displays SNO counts", %{conn: conn} do
      sno_fixture(%{status: "pending"})
      sno_fixture(%{status: "validated"})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Total SNOs"
    end

    test "displays recent SNOs", %{conn: conn} do
      _sno = sno_fixture(%{claim: "Dashboard test claim"})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Recent SNOs"
      assert html =~ "Dashboard test claim"
    end

    test "displays active experiments", %{conn: conn} do
      experiment = experiment_fixture(%{name: "Active Experiment", status: "running"})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Active Experiments"
      assert html =~ experiment.name
    end

    test "links to SNO list", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert view
             |> element("a", "View all")
             |> has_element?()
    end
  end
end
