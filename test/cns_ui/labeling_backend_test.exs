defmodule CnsUi.LabelingBackendTest do
  use CnsUi.DataCase, async: true

  alias CnsUi.LabelingBackend
  alias CnsUi.SNOs
  alias LabelingIR.{Assignment, Label}

  describe "get_next_assignment/3" do
    test "returns assignment for sno_validation queue with pending SNO" do
      # Create a pending SNO
      {:ok, sno} =
        SNOs.create_sno(%{
          claim: "Test claim",
          evidence: %{text: "Test evidence"},
          confidence: 0.8,
          status: "pending",
          provenance: %{source: "test"},
          metadata: %{}
        })

      assert {:ok, %Assignment{} = assignment} =
               LabelingBackend.get_next_assignment("sno_validation", "user123")

      assert assignment.id == "sno_validation:#{sno.id}"
      assert assignment.queue_id == "sno_validation"
      assert assignment.sample.payload.claim == "Test claim"
      assert length(assignment.schema.fields) == 2
    end

    test "returns no_assignments when sno_validation queue is empty" do
      assert {:error, :no_assignments} =
               LabelingBackend.get_next_assignment("sno_validation", "user123")
    end

    test "returns not_found for invalid queue" do
      assert {:error, :not_found} =
               LabelingBackend.get_next_assignment("invalid_queue", "user123")
    end

    test "returns no_assignments for antagonist_review queue (not implemented)" do
      assert {:error, :no_assignments} =
               LabelingBackend.get_next_assignment("antagonist_review", "user123")
    end

    test "returns no_assignments for synthesis_verification queue (not implemented)" do
      assert {:error, :no_assignments} =
               LabelingBackend.get_next_assignment("synthesis_verification", "user123")
    end
  end

  describe "submit_label/3" do
    setup do
      {:ok, sno} =
        SNOs.create_sno(%{
          claim: "Test claim",
          evidence: %{text: "Test evidence"},
          confidence: 0.8,
          status: "pending",
          provenance: %{source: "test"},
          metadata: %{}
        })

      %{sno: sno}
    end

    test "accepts SNO when validation is accept", %{sno: sno} do
      assignment_id = "sno_validation:#{sno.id}"

      label_data = %{
        values: %{"validation" => "accept", "notes" => "Looks good"},
        user_id: "user123",
        time_spent_ms: 30000
      }

      assert {:ok, %Label{} = label} = LabelingBackend.submit_label(assignment_id, label_data)

      assert label.assignment_id == assignment_id
      assert label.user_id == "user123"
      assert label.values["validation"] == "accept"

      # Verify SNO status updated
      updated_sno = SNOs.get_sno!(sno.id)
      assert updated_sno.status == "validated"
    end

    test "rejects SNO when validation is reject", %{sno: sno} do
      assignment_id = "sno_validation:#{sno.id}"

      label_data = %{
        values: %{"validation" => "reject", "notes" => "Citation invalid"},
        user_id: "user123",
        time_spent_ms: 20000
      }

      assert {:ok, %Label{}} = LabelingBackend.submit_label(assignment_id, label_data)

      # Verify SNO status updated
      updated_sno = SNOs.get_sno!(sno.id)
      assert updated_sno.status == "rejected"
    end

    test "keeps status when validation is needs_review", %{sno: sno} do
      assignment_id = "sno_validation:#{sno.id}"

      label_data = %{
        values: %{"validation" => "needs_review", "notes" => "Expert review required"},
        user_id: "user123",
        time_spent_ms: 15000
      }

      assert {:ok, %Label{}} = LabelingBackend.submit_label(assignment_id, label_data)

      # Verify SNO status unchanged
      updated_sno = SNOs.get_sno!(sno.id)
      assert updated_sno.status == "pending"
    end

    test "accepts Label struct", %{sno: sno} do
      assignment_id = "sno_validation:#{sno.id}"

      label_struct = %Label{
        id: "test_label_#{sno.id}",
        assignment_id: assignment_id,
        sample_id: "sno:#{sno.id}",
        queue_id: "sno_validation",
        tenant_id: "cns_ui",
        namespace: "sno_validation",
        user_id: "user123",
        values: %{"validation" => "accept"},
        notes: "Test",
        time_spent_ms: 10000,
        created_at: DateTime.utc_now(),
        lineage_ref: nil,
        metadata: %{}
      }

      assert {:ok, %Label{}} = LabelingBackend.submit_label(assignment_id, label_struct)
    end

    test "returns error for invalid assignment_id format" do
      label_data = %{
        values: %{"validation" => "accept"},
        user_id: "user123"
      }

      assert {:error, {:validation, errors}} =
               LabelingBackend.submit_label("invalid_format", label_data)

      assert errors.assignment_id == ["invalid format"]
    end

    test "returns error when SNO not found" do
      assignment_id = "sno_validation:99999"

      label_data = %{
        values: %{"validation" => "accept"},
        user_id: "user123"
      }

      assert {:error, :not_found} = LabelingBackend.submit_label(assignment_id, label_data)
    end

    test "returns error for non-numeric SNO ID" do
      assignment_id = "sno_validation:abc"

      label_data = %{
        values: %{"validation" => "accept"},
        user_id: "user123"
      }

      assert {:error, {:validation, errors}} =
               LabelingBackend.submit_label(assignment_id, label_data)

      assert errors.sno_id == ["invalid format"]
    end
  end

  describe "get_queue_stats/2" do
    setup do
      # Create SNOs with different statuses
      {:ok, _} =
        SNOs.create_sno(%{
          claim: "SNO 1",
          evidence: %{text: "Evidence 1"},
          confidence: 0.9,
          status: "pending",
          provenance: %{},
          metadata: %{}
        })

      {:ok, _} =
        SNOs.create_sno(%{
          claim: "SNO 2",
          evidence: %{text: "Evidence 2"},
          confidence: 0.8,
          status: "validated",
          provenance: %{},
          metadata: %{}
        })

      {:ok, _} =
        SNOs.create_sno(%{
          claim: "SNO 3",
          evidence: %{text: "Evidence 3"},
          confidence: 0.7,
          status: "rejected",
          provenance: %{},
          metadata: %{}
        })

      :ok
    end

    test "returns statistics for sno_validation queue" do
      assert {:ok, stats} = LabelingBackend.get_queue_stats("sno_validation")

      assert stats.total >= 3
      assert stats.pending >= 1
      assert stats.validated >= 1
      assert stats.rejected >= 1
      assert stats.remaining >= 1
    end

    test "returns empty stats for antagonist_review queue" do
      assert {:ok, stats} = LabelingBackend.get_queue_stats("antagonist_review")

      assert stats.total == 0
      assert stats.pending == 0
      assert stats.remaining == 0
    end

    test "returns empty stats for synthesis_verification queue" do
      assert {:ok, stats} = LabelingBackend.get_queue_stats("synthesis_verification")

      assert stats.total == 0
      assert stats.pending == 0
      assert stats.remaining == 0
    end

    test "returns error for invalid queue" do
      assert {:error, :not_found} = LabelingBackend.get_queue_stats("invalid_queue")
    end
  end

  describe "check_queue_access/3" do
    test "allows access to all queues for all users (current implementation)" do
      assert {:ok, true} = LabelingBackend.check_queue_access("user123", "sno_validation")
      assert {:ok, true} = LabelingBackend.check_queue_access("user456", "antagonist_review")

      assert {:ok, true} =
               LabelingBackend.check_queue_access("user789", "synthesis_verification")
    end
  end
end
