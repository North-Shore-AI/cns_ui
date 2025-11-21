defmodule CnsUiWeb.ExperimentLiveTest do
  use CnsUiWeb.ConnCase

  import Phoenix.LiveViewTest
  import CnsUi.ExperimentsFixtures

  describe "Index" do
    test "lists all experiments", %{conn: conn} do
      experiment = experiment_fixture(%{name: "Test Experiment"})

      {:ok, _view, html} = live(conn, ~p"/experiments")

      assert html =~ "Experiments"
      assert html =~ experiment.name
    end

    test "shows experiment status", %{conn: conn} do
      experiment_fixture(%{status: "running"})

      {:ok, _view, html} = live(conn, ~p"/experiments")

      assert html =~ "running"
    end
  end

  describe "Show" do
    test "displays experiment details", %{conn: conn} do
      experiment = experiment_fixture(%{name: "Detail Test", description: "Test description"})

      {:ok, _view, html} = live(conn, ~p"/experiments/#{experiment.id}")

      assert html =~ experiment.name
      assert html =~ experiment.description
    end

    test "shows training runs section", %{conn: conn} do
      experiment = experiment_fixture()

      {:ok, _view, html} = live(conn, ~p"/experiments/#{experiment.id}")

      assert html =~ "Training Runs"
    end
  end
end
