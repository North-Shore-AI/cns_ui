defmodule CnsUi.SNOsTest do
  use CnsUi.DataCase

  alias CnsUi.SNOs
  alias CnsUi.SNOs.SNO

  import CnsUi.SNOsFixtures

  describe "snos" do
    test "list_snos/0 returns all snos" do
      sno = sno_fixture()
      assert SNOs.list_snos() == [sno]
    end

    test "get_sno!/1 returns the sno with given id" do
      sno = sno_fixture()
      assert SNOs.get_sno!(sno.id) == sno
    end

    test "create_sno/1 with valid data creates a sno" do
      valid_attrs = %{claim: "Test claim", confidence: 0.9, status: "pending"}

      assert {:ok, %SNO{} = sno} = SNOs.create_sno(valid_attrs)
      assert sno.claim == "Test claim"
      assert sno.confidence == 0.9
      assert sno.status == "pending"
    end

    test "create_sno/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SNOs.create_sno(%{claim: nil})
    end

    test "create_sno/1 validates confidence range" do
      assert {:error, changeset} = SNOs.create_sno(%{claim: "Test", confidence: 1.5})
      assert "must be less than or equal to 1.0" in errors_on(changeset).confidence
    end

    test "create_sno/1 validates status values" do
      assert {:error, changeset} =
               SNOs.create_sno(%{claim: "Test", confidence: 0.5, status: "invalid"})

      assert "is invalid" in errors_on(changeset).status
    end

    test "update_sno/2 with valid data updates the sno" do
      sno = sno_fixture()
      update_attrs = %{confidence: 0.95}

      assert {:ok, %SNO{} = updated_sno} = SNOs.update_sno(sno, update_attrs)
      assert updated_sno.confidence == 0.95
    end

    test "delete_sno/1 deletes the sno" do
      sno = sno_fixture()
      assert {:ok, %SNO{}} = SNOs.delete_sno(sno)
      assert_raise Ecto.NoResultsError, fn -> SNOs.get_sno!(sno.id) end
    end

    test "change_sno/1 returns a sno changeset" do
      sno = sno_fixture()
      assert %Ecto.Changeset{} = SNOs.change_sno(sno)
    end

    test "high_confidence_snos/1 returns snos above threshold" do
      low_sno = sno_fixture(%{confidence: 0.5})
      high_sno = sno_fixture(%{confidence: 0.9})

      result = SNOs.high_confidence_snos(0.8)
      assert high_sno in result
      refute low_sno in result
    end

    test "recent_snos/1 returns limited recent snos" do
      for _ <- 1..5, do: sno_fixture()

      result = SNOs.recent_snos(3)
      assert length(result) == 3
    end

    test "count_by_status/0 returns counts by status" do
      sno_fixture(%{status: "pending"})
      sno_fixture(%{status: "pending"})
      sno_fixture(%{status: "validated"})

      counts = SNOs.count_by_status()
      assert counts["pending"] == 2
      assert counts["validated"] == 1
    end

    test "list_snos/1 with filters" do
      _sno1 = sno_fixture(%{status: "pending", confidence: 0.5})
      sno2 = sno_fixture(%{status: "validated", confidence: 0.9})

      # Filter by status
      assert [^sno2] = SNOs.list_snos(status: "validated")

      # Filter by min confidence
      assert [^sno2] = SNOs.list_snos(min_confidence: 0.8)

      # Filter by search
      sno3 = sno_fixture(%{claim: "unique searchable claim"})
      assert [^sno3] = SNOs.list_snos(search: "searchable")
    end
  end
end
