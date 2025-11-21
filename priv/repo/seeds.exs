# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CnsUi.Repo.insert!(%CnsUi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CnsUi.{SNOs, Experiments, Training, Citations, Challenges, Metrics}

# Create sample SNOs
{:ok, sno1} =
  SNOs.create_sno(%{
    claim: "Large language models can generate coherent text across multiple domains.",
    confidence: 0.92,
    status: "validated",
    evidence: %{
      "source" => "research_paper",
      "citations" => 15
    },
    provenance: %{
      "created_by" => "proposer",
      "version" => "1.0"
    },
    metadata: %{
      "domain" => "NLP",
      "complexity" => "high"
    }
  })

{:ok, sno2} =
  SNOs.create_sno(%{
    claim: "Fine-tuning with LoRA reduces computational requirements significantly.",
    confidence: 0.88,
    status: "validated",
    evidence: %{
      "source" => "benchmark",
      "reduction" => "90%"
    },
    parent_id: sno1.id
  })

{:ok, sno3} =
  SNOs.create_sno(%{
    claim: "Dialectical reasoning improves model consistency.",
    confidence: 0.75,
    status: "pending",
    evidence: %{}
  })

# Create sample experiment
{:ok, experiment} =
  Experiments.create_experiment(%{
    name: "CNS 3.0 Baseline",
    description: "Baseline experiment for CNS 3.0 metrics validation",
    status: "running",
    config: %{
      "model" => "llama-7b",
      "lora_rank" => 8,
      "learning_rate" => 0.0001
    },
    dataset_path: "/data/cns_baseline.json"
  })

# Create sample training run
{:ok, run} =
  Training.create_training_run(%{
    experiment_id: experiment.id,
    status: "running",
    lora_config: %{
      "rank" => 8,
      "alpha" => 16,
      "dropout" => 0.1
    },
    checkpoints: ["checkpoint_100", "checkpoint_200"]
  })

# Create sample metrics
Metrics.create_metrics_snapshot(%{
  run_id: run.id,
  entailment: 0.92,
  chirality: 0.35,
  fisher_rao: 0.15,
  pass_rate: 0.88,
  timestamp: DateTime.utc_now()
})

# Create sample citations
Citations.create_citation(%{
  sno_id: sno1.id,
  source_id: "arxiv:2301.00001",
  source_type: "paper",
  validity_score: 0.95,
  grounding_score: 0.88
})

Citations.create_citation(%{
  sno_id: sno2.id,
  source_id: "github:lora-benchmark",
  source_type: "benchmark",
  validity_score: 0.90,
  grounding_score: 0.92
})

# Create sample challenges
Challenges.create_challenge(%{
  sno_id: sno3.id,
  challenge_type: "insufficient_evidence",
  severity: "medium",
  description: "The claim lacks quantitative evidence to support the improvement assertion."
})

IO.puts("Seeds completed successfully!")
