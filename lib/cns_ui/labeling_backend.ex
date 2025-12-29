defmodule CnsUi.LabelingBackend do
  @moduledoc """
  CNS-specific backend implementation for Ingot labeling features.

  Provides labeling operations for SNO (Structured Narrative Object) annotation,
  allowing human reviewers to validate claims, evidence, and dialectical reasoning
  in the CNS dialectical workflow.

  ## CNS Labeling Workflow

  This backend integrates Ingot's composable labeling UI with CNS's dialectical
  reasoning pipeline. It supports three distinct annotation queues corresponding
  to the CNS 3.0 agent architecture:

  ### Queue Types

  1. **SNO Validation** (`sno_validation`)
     - Validates Proposer agent output
     - Reviews claim grounding and evidence quality
     - Checks citation accuracy and entailment scores
     - Gates synthesis based on human-verified quality

  2. **Antagonist Review** (`antagonist_review`) - Future
     - Reviews Antagonist agent flags for contradictions
     - Adjudicates high-chirality/high-β₁ conflicts
     - Validates contradiction detection precision

  3. **Synthesis Verification** (`synthesis_verification`) - Future
     - Verifies Synthesizer agent output quality
     - Checks β₁ reduction and topological coherence
     - Validates synthesis against competing evidence

  ## Integration with CNS Contexts

  This backend supports two modes:

  ### Local Mode (default, for development)
  - Delegates to existing CNS contexts (`CnsUi.SNOs`, etc.)
  - Stores labels in local database
  - Uses in-memory queue management

  ### Anvil Mode (for production)
  - Delegates to Ingot.AnvilClient for queue management
  - Uses real Anvil HTTP endpoints for assignments and labels
  - Enables distributed labeling with full Anvil features

  Configure via `:cns_ui, :labeling_mode` (`:local` or `:anvil`)

  ## Error Handling

  All callbacks return structured errors:
  - `{:error, :not_found}` - Resource doesn't exist
  - `{:error, :no_assignments}` - Queue is empty
  - `{:error, {:validation, changeset}}` - Invalid data
  - `{:error, exception}` - Unexpected error

  ## Logging and Telemetry

  Key operations emit telemetry events:
  - `[:cns_ui, :labeling, :assignment, :fetched]`
  - `[:cns_ui, :labeling, :label, :submitted]`
  - `[:cns_ui, :labeling, :queue, :stats]`

  ## Examples

      # Get next assignment from SNO validation queue
      {:ok, assignment} = CnsUi.LabelingBackend.get_next_assignment("sno_validation", "user123")

      # Submit validation label
      label_data = %{
        values: %{"validation" => "accept", "notes" => "Citation checks out"},
        user_id: "user123",
        time_spent_ms: 45000
      }
      {:ok, label} = CnsUi.LabelingBackend.submit_label(assignment.id, label_data)

      # Get queue statistics
      {:ok, stats} = CnsUi.LabelingBackend.get_queue_stats("sno_validation")
      # => %{total: 100, pending: 20, validated: 70, rejected: 10}
  """

  @behaviour Ingot.Labeling.Backend

  require Logger

  alias CnsUi.SNOs
  alias CnsUi.LabelingBackend.QueueConfig
  alias Ingot.AnvilClient
  alias LabelingIR.{Assignment, Label, Sample, Schema}
  alias LabelingIR.Schema.Field

  @doc """
  Retrieves the next assignment for a user from the specified queue.

  ## Parameters

  - `queue_id` - Queue identifier (e.g., "sno_validation")
  - `user_id` - User identifier requesting assignment
  - `opts` - Optional keyword list (future: filtering, priority)

  ## Returns

  - `{:ok, %Assignment{}}` - Next assignment with sample and schema
  - `{:error, :no_assignments}` - Queue is empty
  - `{:error, :not_found}` - Queue doesn't exist

  ## Examples

      iex> get_next_assignment("sno_validation", "user123")
      {:ok, %Assignment{id: "sno_validation:42", ...}}

      iex> get_next_assignment("invalid_queue", "user123")
      {:error, :not_found}
  """
  @impl true
  def get_next_assignment(queue_id, user_id, opts \\ []) do
    Logger.info("Fetching assignment from queue=#{queue_id} for user=#{user_id}")

    result =
      case labeling_mode() do
        :anvil ->
          get_next_assignment_from_anvil(queue_id, user_id, opts)

        :local ->
          get_next_assignment_local(queue_id, user_id, opts)
      end

    # Emit telemetry
    :telemetry.execute(
      [:cns_ui, :labeling, :assignment, :fetched],
      %{count: 1},
      %{queue_id: queue_id, user_id: user_id, result: elem(result, 0)}
    )

    result
  end

  @doc """
  Submits a label for an assignment.

  ## Parameters

  - `assignment_id` - Assignment identifier in format "{queue_id}:{resource_id}"
  - `label_data` - Label data (map or %Label{} struct)
  - `opts` - Optional keyword list

  ## Returns

  - `{:ok, %Label{}}` - Successfully stored label
  - `{:error, :not_found}` - Assignment/resource not found
  - `{:error, {:validation, errors}}` - Invalid label data

  ## Examples

      iex> submit_label("sno_validation:42", %{values: %{"validation" => "accept"}})
      {:ok, %Label{id: "label:42:...", ...}}
  """
  def submit_label(assignment_id, label_data, opts \\ [])

  @impl true
  def submit_label(assignment_id, %Label{} = label, opts) do
    submit_label(assignment_id, Map.from_struct(label), opts)
  end

  def submit_label(assignment_id, label_data, opts) when is_map(label_data) do
    Logger.info("Submitting label for assignment=#{assignment_id}")

    result =
      case labeling_mode() do
        :anvil ->
          submit_label_to_anvil(assignment_id, label_data, opts)

        :local ->
          submit_label_local(assignment_id, label_data, opts)
      end

    # Emit telemetry
    :telemetry.execute(
      [:cns_ui, :labeling, :label, :submitted],
      %{count: 1},
      %{assignment_id: assignment_id, result: elem(result, 0)}
    )

    result
  end

  @doc """
  Retrieves statistics for a labeling queue.

  ## Parameters

  - `queue_id` - Queue identifier
  - `opts` - Optional keyword list

  ## Returns

  - `{:ok, stats_map}` - Queue statistics with counts by status
  - `{:error, :not_found}` - Queue doesn't exist

  ## Examples

      iex> get_queue_stats("sno_validation")
      {:ok, %{total: 100, pending: 20, validated: 70, rejected: 10, remaining: 20}}
  """
  @impl true
  def get_queue_stats(queue_id, opts \\ []) do
    Logger.debug("Fetching stats for queue=#{queue_id}")

    result =
      case labeling_mode() do
        :anvil ->
          get_queue_stats_from_anvil(queue_id, opts)

        :local ->
          get_queue_stats_local(queue_id, opts)
      end

    # Emit telemetry
    :telemetry.execute(
      [:cns_ui, :labeling, :queue, :stats],
      %{count: 1},
      %{queue_id: queue_id, result: elem(result, 0)}
    )

    result
  end

  @doc """
  Checks if a user has access to a specific queue.

  ## Parameters

  - `user_id` - User identifier
  - `queue_id` - Queue identifier
  - `opts` - Optional keyword list

  ## Returns

  - `{:ok, true}` - User has access
  - `{:ok, false}` - User doesn't have access
  - `{:error, reason}` - Error checking access

  ## Note

  Currently allows all users access to all queues.
  Future: implement role-based access control (RBAC).

  ## Examples

      iex> check_queue_access("user123", "sno_validation")
      {:ok, true}
  """
  @impl true
  def check_queue_access(_user_id, _queue_id, _opts \\ []) do
    # For now, allow all users access to all queues
    # Future: implement role-based access control
    # Example RBAC logic:
    # - Domain experts → all queues
    # - Annotators → sno_validation only
    # - Reviewers → antagonist_review, synthesis_verification
    {:ok, true}
  end

  # Private helper functions

  # Returns the configured labeling mode (:local or :anvil)
  defp labeling_mode do
    Application.get_env(:cns_ui, :labeling_mode, :local)
  end

  # ========================================
  # Anvil Mode Implementation
  # ========================================

  # Fetches next assignment from Anvil service
  defp get_next_assignment_from_anvil(queue_id, user_id, opts) do
    Logger.debug("Fetching assignment from Anvil: queue=#{queue_id}, user=#{user_id}")

    case AnvilClient.get_next_assignment(queue_id, user_id, opts) do
      {:ok, assignment} ->
        {:ok, assignment}

      {:error, reason} ->
        Logger.debug("Anvil returned error for queue #{queue_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Submits label to Anvil service
  defp submit_label_to_anvil(assignment_id, label_data, opts) do
    Logger.debug("Submitting label to Anvil: assignment=#{assignment_id}")

    # Convert map to Label struct if needed
    label = ensure_label_struct(assignment_id, label_data)

    case AnvilClient.submit_label(assignment_id, label, opts) do
      {:ok, submitted_label} ->
        # Also update local SNO status if this is an SNO validation
        case String.split(assignment_id, ":", parts: 2) do
          ["sno_validation", sno_id] ->
            update_local_sno_from_label(sno_id, label_data)

          _ ->
            :ok
        end

        {:ok, submitted_label}

      {:error, reason} ->
        Logger.error("Failed to submit label to Anvil: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Gets queue statistics from Anvil service
  defp get_queue_stats_from_anvil(queue_id, opts) do
    Logger.debug("Fetching queue stats from Anvil: queue=#{queue_id}")

    case AnvilClient.get_queue_stats(queue_id, opts) do
      {:ok, stats} ->
        {:ok, stats}

      {:error, reason} ->
        Logger.debug("Anvil returned error for stats: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Ensures label_data is converted to a Label struct
  defp ensure_label_struct(_assignment_id, %Label{} = label), do: label

  defp ensure_label_struct(assignment_id, label_data) when is_map(label_data) do
    [queue_id | _] = String.split(assignment_id, ":", parts: 2)

    %Label{
      id: Map.get(label_data, :id) || Map.get(label_data, "id") || generate_label_id(),
      assignment_id: assignment_id,
      sample_id: Map.get(label_data, :sample_id) || Map.get(label_data, "sample_id"),
      queue_id: queue_id,
      tenant_id: Map.get(label_data, :tenant_id) || Map.get(label_data, "tenant_id") || "cns_ui",
      namespace:
        Map.get(label_data, :namespace) || Map.get(label_data, "namespace") ||
          QueueConfig.namespace_for_queue(queue_id),
      user_id: Map.get(label_data, :user_id) || Map.get(label_data, "user_id") || "unknown",
      values: Map.get(label_data, :values) || Map.get(label_data, "values") || %{},
      notes: Map.get(label_data, :notes) || Map.get(label_data, "notes"),
      time_spent_ms:
        Map.get(label_data, :time_spent_ms) || Map.get(label_data, "time_spent_ms") || 0,
      created_at: DateTime.utc_now(),
      lineage_ref: Map.get(label_data, :lineage_ref) || Map.get(label_data, "lineage_ref"),
      metadata: Map.get(label_data, :metadata) || Map.get(label_data, "metadata") || %{}
    }
  end

  # Generates a unique label ID
  defp generate_label_id do
    "label:#{System.unique_integer([:positive, :monotonic])}"
  end

  # Updates local SNO status based on label submission (for Anvil mode)
  defp update_local_sno_from_label(sno_id, label_data) do
    try do
      sno_id_int = String.to_integer(sno_id)

      case SNOs.get_sno!(sno_id_int) do
        nil ->
          :ok

        sno ->
          values = Map.get(label_data, :values) || Map.get(label_data, "values") || %{}
          validation_result = Map.get(values, "validation") || Map.get(values, :validation)

          new_status =
            case validation_result do
              "accept" -> "validated"
              "reject" -> "rejected"
              _ -> sno.status
            end

          metadata =
            Map.merge(sno.metadata, %{
              last_labeled_at: DateTime.utc_now(),
              validation: validation_result,
              label_metadata: Map.get(label_data, :metadata) || Map.get(label_data, "metadata")
            })

          SNOs.update_sno(sno, %{status: new_status, metadata: metadata})
      end
    rescue
      _ -> :ok
    end
  end

  # ========================================
  # Local Mode Implementation
  # ========================================

  # Fetches next assignment using local database
  defp get_next_assignment_local(queue_id, user_id, opts) do
    case queue_id do
      "sno_validation" ->
        get_next_sno_for_validation(user_id, opts)

      "antagonist_review" ->
        get_next_antagonist_flag(user_id, opts)

      "synthesis_verification" ->
        get_next_synthesis_candidate(user_id, opts)

      _ ->
        Logger.warning("Unknown queue requested: #{queue_id}")
        {:error, :not_found}
    end
  end

  # Submits label using local database
  defp submit_label_local(assignment_id, label_data, opts) do
    case String.split(assignment_id, ":", parts: 2) do
      [queue_id, resource_id] ->
        store_label(queue_id, resource_id, label_data, opts)

      _ ->
        Logger.error("Invalid assignment_id format: #{assignment_id}")
        {:error, {:validation, %{assignment_id: ["invalid format"]}}}
    end
  end

  # Gets queue stats using local database
  defp get_queue_stats_local(queue_id, opts) do
    case queue_id do
      "sno_validation" ->
        get_sno_validation_stats(opts)

      "antagonist_review" ->
        get_antagonist_review_stats(opts)

      "synthesis_verification" ->
        get_synthesis_verification_stats(opts)

      _ ->
        Logger.warning("Unknown queue for stats: #{queue_id}")
        {:error, :not_found}
    end
  end

  # Retrieves the next SNO pending validation.
  # Currently returns oldest pending SNO; future: implement user-aware assignment
  # to prevent duplicate labeling and enable inter-rater reliability checks.
  defp get_next_sno_for_validation(_user_id, _opts) do
    case SNOs.list_snos(status: "pending", limit: 1) do
      [sno | _] ->
        # Create a Sample struct for the SNO
        sample = %Sample{
          id: "sno:#{sno.id}",
          tenant_id: "cns_ui",
          namespace: "sno_validation",
          pipeline_id: "sno_labeling",
          payload: %{
            sno_id: sno.id,
            claim: sno.claim,
            evidence: sno.evidence,
            confidence: sno.confidence,
            provenance: sno.provenance
          },
          artifacts: [],
          metadata: %{
            status: sno.status
          },
          lineage_ref: nil,
          created_at: sno.inserted_at || DateTime.utc_now()
        }

        # Create a Schema struct for the labeling task
        schema = %Schema{
          id: "sno_validation_schema",
          tenant_id: "cns_ui",
          namespace: "sno_validation",
          fields: [
            %Field{
              name: "validation",
              type: :select,
              required: true,
              options: ["accept", "reject", "needs_review"],
              help: "Validation Result"
            },
            %Field{
              name: "notes",
              type: :text,
              required: false,
              help: "Additional notes about this SNO"
            }
          ],
          layout: nil,
          component_module: nil,
          metadata: %{}
        }

        assignment = %Assignment{
          id: "sno_validation:#{sno.id}",
          queue_id: "sno_validation",
          tenant_id: "cns_ui",
          namespace: "sno_validation",
          sample: sample,
          schema: schema,
          existing_labels: [],
          expires_at: nil,
          lineage_ref: nil,
          metadata: %{
            sno_id: sno.id,
            status: sno.status
          }
        }

        {:ok, assignment}

      [] ->
        Logger.debug("No pending SNOs available for validation")
        {:error, :no_assignments}
    end
  rescue
    exception ->
      Logger.error("Error fetching SNO for validation: #{inspect(exception)}")
      {:error, exception}
  end

  # Retrieves the next Antagonist flag for review.
  # Future implementation will integrate with Antagonist agent output.
  defp get_next_antagonist_flag(_user_id, _opts) do
    # Future: Query antagonist_flags table for HIGH severity flags
    # with status "pending_review", ordered by β₁ score descending
    Logger.debug("Antagonist review queue not yet implemented")
    {:error, :no_assignments}
  end

  # Retrieves the next synthesis candidate for verification.
  # Future implementation will integrate with Synthesizer agent output.
  defp get_next_synthesis_candidate(_user_id, _opts) do
    # Future: Query synthesis_candidates table for status "pending_verification"
    # with β₁_reduction ≥ 30%, ordered by chirality score descending
    Logger.debug("Synthesis verification queue not yet implemented")
    {:error, :no_assignments}
  end

  # Stores a validation label for an SNO and updates its status.
  # Maps validation result to SNO status:
  # - "accept" → "validated"
  # - "reject" → "rejected"
  # - "needs_review" → keeps current status, flags for expert review
  defp store_label("sno_validation", sno_id, label_data, _opts) do
    # Update SNO status based on label
    sno_id_int = String.to_integer(sno_id)

    case SNOs.get_sno!(sno_id_int) do
      nil ->
        {:error, :not_found}

      sno ->
        # Extract validation values from label_data
        values = Map.get(label_data, :values) || Map.get(label_data, "values") || %{}
        validation_result = Map.get(values, "validation") || Map.get(values, :validation)

        # Determine new status based on validation
        new_status =
          case validation_result do
            "accept" -> "validated"
            "reject" -> "rejected"
            _ -> sno.status
          end

        # Update SNO with label metadata
        metadata =
          Map.merge(sno.metadata, %{
            last_labeled_at: DateTime.utc_now(),
            validation: validation_result,
            label_metadata: Map.get(label_data, :metadata) || Map.get(label_data, "metadata")
          })

        case SNOs.update_sno(sno, %{status: new_status, metadata: metadata}) do
          {:ok, _updated_sno} ->
            # Convert to Label struct
            label = %Label{
              id: "label:#{sno_id}:#{System.unique_integer([:positive])}",
              assignment_id: "sno_validation:#{sno_id}",
              sample_id: "sno:#{sno_id}",
              queue_id: "sno_validation",
              tenant_id: "cns_ui",
              namespace: "sno_validation",
              user_id:
                Map.get(label_data, :user_id) || Map.get(label_data, "user_id") || "unknown",
              values: values,
              notes: Map.get(label_data, :notes) || Map.get(label_data, "notes"),
              time_spent_ms:
                Map.get(label_data, :time_spent_ms) || Map.get(label_data, "time_spent_ms") || 0,
              created_at: DateTime.utc_now(),
              lineage_ref: nil,
              metadata: metadata
            }

            {:ok, label}

          {:error, changeset} ->
            {:error, {:validation, changeset}}
        end
    end
  rescue
    Ecto.NoResultsError ->
      {:error, :not_found}

    ArgumentError ->
      {:error, {:validation, %{sno_id: ["invalid format"]}}}
  end

  # Fallback for unimplemented queue types
  defp store_label(queue_id, _resource_id, _label_data, _opts) do
    Logger.warning("Label storage not implemented for queue: #{queue_id}")
    {:error, :not_found}
  end

  # Computes statistics for SNO validation queue.
  # Returns counts by status and total remaining work.
  defp get_sno_validation_stats(_opts) do
    status_counts = SNOs.count_by_status()

    stats = %{
      total: Enum.sum(Map.values(status_counts)),
      pending: Map.get(status_counts, "pending", 0),
      validated: Map.get(status_counts, "validated", 0),
      rejected: Map.get(status_counts, "rejected", 0),
      synthesized: Map.get(status_counts, "synthesized", 0),
      remaining: Map.get(status_counts, "pending", 0)
    }

    {:ok, stats}
  rescue
    exception ->
      Logger.error("Error computing SNO validation stats: #{inspect(exception)}")
      {:error, exception}
  end

  # Computes statistics for Antagonist review queue.
  # Future: integrate with antagonist_flags table.
  defp get_antagonist_review_stats(_opts) do
    # Future: SELECT COUNT(*) FROM antagonist_flags GROUP BY severity, status
    {:ok, %{total: 0, pending: 0, remaining: 0}}
  end

  # Computes statistics for synthesis verification queue.
  # Future: integrate with synthesis_candidates table.
  defp get_synthesis_verification_stats(_opts) do
    # Future: SELECT COUNT(*) FROM synthesis_candidates GROUP BY status
    {:ok, %{total: 0, pending: 0, remaining: 0}}
  end
end
