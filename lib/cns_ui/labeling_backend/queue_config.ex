defmodule CnsUi.LabelingBackend.QueueConfig do
  @moduledoc """
  Configuration for CNS annotation queues.

  Defines queue metadata, schemas, and policies for the three CNS 3.0
  dialectical agent queues:

  1. **sno_validation** - Proposer output validation
  2. **antagonist_review** - Antagonist contradiction review
  3. **synthesis_verification** - Synthesizer output verification

  ## Queue Definitions

  Each queue has:
  - Queue ID and namespace
  - Label schema (fields, types, validation)
  - Sample type and expected payload structure
  - Success criteria and quality gates

  ## Usage

      # Get queue configuration
      config = QueueConfig.get_queue_config("sno_validation")

      # Get namespace for a queue
      namespace = QueueConfig.namespace_for_queue("sno_validation")

      # List all available queues
      queues = QueueConfig.available_queues()
  """

  alias LabelingIR.Schema
  alias LabelingIR.Schema.Field

  @type queue_id :: String.t()
  @type namespace :: String.t()

  @doc """
  Returns the configuration for a specific queue.

  ## Examples

      iex> get_queue_config("sno_validation")
      %{
        queue_id: "sno_validation",
        namespace: "sno_validation",
        name: "SNO Validation",
        description: "Validate Proposer agent output...",
        schema: %Schema{...},
        sample_type: :sno,
        ...
      }
  """
  @spec get_queue_config(queue_id()) :: map() | nil
  def get_queue_config(queue_id) do
    case queue_id do
      "sno_validation" -> sno_validation_config()
      "antagonist_review" -> antagonist_review_config()
      "synthesis_verification" -> synthesis_verification_config()
      _ -> nil
    end
  end

  @doc """
  Returns the namespace for a given queue ID.

  ## Examples

      iex> namespace_for_queue("sno_validation")
      "sno_validation"
  """
  @spec namespace_for_queue(queue_id()) :: namespace()
  def namespace_for_queue(queue_id) do
    case get_queue_config(queue_id) do
      %{namespace: namespace} -> namespace
      _ -> queue_id
    end
  end

  @doc """
  Lists all available queue IDs.

  ## Examples

      iex> available_queues()
      ["sno_validation", "antagonist_review", "synthesis_verification"]
  """
  @spec available_queues() :: [queue_id()]
  def available_queues do
    ["sno_validation", "antagonist_review", "synthesis_verification"]
  end

  @doc """
  Returns the label schema for a specific queue.

  ## Examples

      iex> get_schema("sno_validation")
      %Schema{id: "sno_validation_schema", ...}
  """
  @spec get_schema(queue_id()) :: Schema.t() | nil
  def get_schema(queue_id) do
    case get_queue_config(queue_id) do
      %{schema: schema} -> schema
      _ -> nil
    end
  end

  # Private queue configuration functions

  defp sno_validation_config do
    %{
      queue_id: "sno_validation",
      namespace: "sno_validation",
      name: "SNO Validation",
      description: """
      Validate Proposer agent output for claim grounding and evidence quality.

      Reviewers check:
      - Citation accuracy (referenced sentences exist and support claim)
      - Entailment score (claim supported by evidence)
      - Schema compliance (CLAIM[c*] format)
      - Overall quality for synthesis readiness
      """,
      schema: sno_validation_schema(),
      sample_type: :sno,
      tenant_id: "cns_ui",
      metadata: %{
        agent: "proposer",
        stage: "validation",
        success_criteria: %{
          citation_accuracy: 0.96,
          entailment_threshold: 0.75,
          schema_compliance: 1.0
        }
      }
    }
  end

  defp antagonist_review_config do
    %{
      queue_id: "antagonist_review",
      namespace: "antagonist_review",
      name: "Antagonist Review",
      description: """
      Review Antagonist agent flags for contradiction detection.

      Reviewers adjudicate:
      - High-severity contradiction flags
      - β₁ (topological hole) score validity
      - Chirality and entanglement metrics
      - False positive vs. genuine conflicts
      """,
      schema: antagonist_review_schema(),
      sample_type: :sno_pair,
      tenant_id: "cns_ui",
      metadata: %{
        agent: "antagonist",
        stage: "review",
        success_criteria: %{
          precision: 0.8,
          recall: 0.7,
          beta1_accuracy: 0.9
        }
      }
    }
  end

  defp synthesis_verification_config do
    %{
      queue_id: "synthesis_verification",
      namespace: "synthesis_verification",
      name: "Synthesis Verification",
      description: """
      Verify Synthesizer agent output quality and coherence.

      Reviewers validate:
      - β₁ reduction ≥30% from input SNOs
      - All critic scores pass thresholds
      - Synthesis preserves provenance
      - No hallucinated claims or evidence
      """,
      schema: synthesis_verification_schema(),
      sample_type: :synthesized_sno,
      tenant_id: "cns_ui",
      metadata: %{
        agent: "synthesizer",
        stage: "verification",
        success_criteria: %{
          beta1_reduction: 0.3,
          critic_pass_rate: 1.0,
          provenance_preserved: 1.0
        }
      }
    }
  end

  # Schema definitions

  defp sno_validation_schema do
    %Schema{
      id: "sno_validation_schema",
      tenant_id: "cns_ui",
      namespace: "sno_validation",
      fields: [
        %Field{
          name: "validation",
          type: :select,
          required: true,
          options: ["accept", "reject", "needs_review"],
          help: "Validation result based on citation accuracy, entailment, and schema compliance"
        },
        %Field{
          name: "citation_valid",
          type: :boolean,
          required: false,
          help: "Do all cited sentences exist and support the claim?"
        },
        %Field{
          name: "entailment_score",
          type: :scale,
          required: false,
          min: 0,
          max: 1,
          help: "Estimated entailment score (0-1) between claim and evidence"
        },
        %Field{
          name: "issues",
          type: :multiselect,
          required: false,
          options: [
            "hallucinated_citation",
            "weak_entailment",
            "schema_invalid",
            "overgeneralization",
            "missing_evidence"
          ],
          help: "Issues found (select all that apply)"
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
      metadata: %{
        version: "1.0.0",
        created_at: "2025-12-06"
      }
    }
  end

  defp antagonist_review_schema do
    %Schema{
      id: "antagonist_review_schema",
      tenant_id: "cns_ui",
      namespace: "antagonist_review",
      fields: [
        %Field{
          name: "verdict",
          type: :select,
          required: true,
          options: ["confirm_contradiction", "false_positive", "needs_expert"],
          help: "Is this a genuine contradiction or false alarm?"
        },
        %Field{
          name: "contradiction_type",
          type: :select,
          required: false,
          options: ["direct_negation", "temporal", "scope", "interpretation"],
          help: "Type of contradiction if confirmed"
        },
        %Field{
          name: "beta1_valid",
          type: :boolean,
          required: false,
          help: "Does the β₁ score accurately reflect topological gap?"
        },
        %Field{
          name: "severity",
          type: :select,
          required: false,
          options: ["low", "medium", "high", "critical"],
          help: "How severe is this contradiction?"
        },
        %Field{
          name: "notes",
          type: :text,
          required: false,
          help: "Reasoning for verdict"
        }
      ],
      layout: nil,
      component_module: nil,
      metadata: %{
        version: "1.0.0",
        created_at: "2025-12-06"
      }
    }
  end

  defp synthesis_verification_schema do
    %Schema{
      id: "synthesis_verification_schema",
      tenant_id: "cns_ui",
      namespace: "synthesis_verification",
      fields: [
        %Field{
          name: "verdict",
          type: :select,
          required: true,
          options: ["accept", "reject", "needs_revision"],
          help: "Accept synthesis, reject it, or request revisions?"
        },
        %Field{
          name: "beta1_reduced",
          type: :boolean,
          required: false,
          help: "Did synthesis achieve ≥30% β₁ reduction?"
        },
        %Field{
          name: "critics_passed",
          type: :boolean,
          required: false,
          help: "Did all critics (Grounding, Logic, Novelty) pass thresholds?"
        },
        %Field{
          name: "provenance_intact",
          type: :boolean,
          required: false,
          help: "Is provenance chain preserved for all claims?"
        },
        %Field{
          name: "issues",
          type: :multiselect,
          required: false,
          options: [
            "hallucinated_synthesis",
            "weak_integration",
            "provenance_lost",
            "critic_failures",
            "insufficient_beta1_reduction"
          ],
          help: "Issues found (select all that apply)"
        },
        %Field{
          name: "notes",
          type: :text,
          required: false,
          help: "Detailed feedback for synthesizer"
        }
      ],
      layout: nil,
      component_module: nil,
      metadata: %{
        version: "1.0.0",
        created_at: "2025-12-06"
      }
    }
  end
end
