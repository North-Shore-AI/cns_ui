defmodule CnsUiWeb.SNOLiveTest do
  use CnsUiWeb.ConnCase

  import Phoenix.LiveViewTest
  import CnsUi.SNOsFixtures

  describe "Index" do
    test "lists all snos", %{conn: conn} do
      sno = sno_fixture(%{claim: "Test SNO claim"})

      {:ok, _view, html} = live(conn, ~p"/snos")

      assert html =~ "Structured Narrative Objects"
      assert html =~ sno.claim
    end

    test "filters snos by search", %{conn: conn} do
      sno1 = sno_fixture(%{claim: "First claim"})
      sno2 = sno_fixture(%{claim: "Second unique claim"})

      {:ok, view, _html} = live(conn, ~p"/snos")

      html =
        view
        |> element("input[name=search]")
        |> render_keyup(%{value: "unique"})

      assert html =~ sno2.claim
      refute html =~ sno1.claim
    end

    test "filters snos by status", %{conn: conn} do
      sno1 = sno_fixture(%{status: "pending"})
      sno2 = sno_fixture(%{status: "validated"})

      {:ok, view, _html} = live(conn, ~p"/snos")

      html =
        view
        |> element("select[name=status]")
        |> render_change(%{status: "validated"})

      assert html =~ sno2.claim
      refute html =~ sno1.claim
    end

    test "changes view mode", %{conn: conn} do
      sno_fixture()

      {:ok, view, _html} = live(conn, ~p"/snos")

      # Click grid view
      html =
        view
        |> element("button", "Grid")
        |> render_click()

      # Grid view should have different class structure
      assert html =~ "grid-cols"
    end
  end

  describe "Show" do
    test "displays sno details", %{conn: conn} do
      sno = sno_fixture(%{claim: "Detail test claim", confidence: 0.85})

      {:ok, _view, html} = live(conn, ~p"/snos/#{sno.id}")

      assert html =~ "SNO ##{sno.id}"
      assert html =~ sno.claim
      assert html =~ "85"
    end

    test "changes tabs", %{conn: conn} do
      sno = sno_fixture()

      {:ok, view, _html} = live(conn, ~p"/snos/#{sno.id}")

      # Click structure tab
      html =
        view
        |> element("button", "Structure")
        |> render_click()

      assert html =~ "Synthesis Chain"
    end

    test "shows evidence tab", %{conn: conn} do
      sno = sno_fixture(%{evidence: %{"key" => "value"}})

      {:ok, view, _html} = live(conn, ~p"/snos/#{sno.id}")

      html =
        view
        |> element("button", "Evidence")
        |> render_click()

      assert html =~ "Evidence"
      assert html =~ "key"
    end
  end
end
