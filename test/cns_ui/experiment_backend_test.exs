defmodule CnsUi.ExperimentBackendTest do
  use CnsUi.DataCase, async: true

  alias CnsUi.ExperimentBackend
  alias CnsUi.Experiments
  alias CnsUi.Training

  describe "list_experiments/1" do
    setup do
      {:ok, exp1} =
        Experiments.create_experiment(%{
          name: "Experiment 1",
          description: "Test experiment",
          config: %{model: "llama-3.1-8b"},
          status: "pending"
        })

      {:ok, exp2} =
        Experiments.create_experiment(%{
          name: "Experiment 2",
          description: "Running experiment",
          config: %{model: "llama-3.1-8b"},
          status: "running"
        })

      {:ok, exp3} =
        Experiments.create_experiment(%{
          name: "Experiment 3",
          description: "Completed experiment",
          config: %{model: "llama-3.1-8b"},
          status: "completed"
        })

      %{exp1: exp1, exp2: exp2, exp3: exp3}
    end

    test "lists all experiments without filters", %{exp1: exp1, exp2: exp2, exp3: exp3} do
      assert {:ok, experiments} = ExperimentBackend.list_experiments()

      assert length(experiments) >= 3
      ids = Enum.map(experiments, & &1.id)
      assert exp1.id in ids
      assert exp2.id in ids
      assert exp3.id in ids
    end

    test "filters experiments by status" do
      assert {:ok, experiments} = ExperimentBackend.list_experiments(status: "running")

      assert Enum.all?(experiments, &(&1.status == "running"))
      assert length(experiments) >= 1
    end

    test "limits number of experiments returned", %{exp1: _exp1, exp2: _exp2, exp3: _exp3} do
      assert {:ok, experiments} = ExperimentBackend.list_experiments(limit: 2)

      assert length(experiments) == 2
    end

    test "combines status filter and limit" do
      # Create more completed experiments
      for i <- 1..5 do
        Experiments.create_experiment(%{
          name: "Completed #{i}",
          description: "Test",
          config: %{},
          status: "completed"
        })
      end

      assert {:ok, experiments} =
               ExperimentBackend.list_experiments(status: "completed", limit: 3)

      assert length(experiments) == 3
      assert Enum.all?(experiments, &(&1.status == "completed"))
    end
  end

  describe "get_experiment/1" do
    test "retrieves experiment by ID" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test Experiment",
          description: "Description",
          config: %{},
          status: "pending"
        })

      assert {:ok, fetched} = ExperimentBackend.get_experiment(experiment.id)
      assert fetched.id == experiment.id
      assert fetched.name == "Test Experiment"
    end

    test "returns not_found for non-existent ID" do
      assert {:error, :not_found} = ExperimentBackend.get_experiment(99999)
    end
  end

  describe "get_experiment_with_associations/1" do
    test "retrieves experiment with training runs preloaded" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test Experiment",
          description: "Description",
          config: %{},
          status: "pending"
        })

      # Create training runs
      {:ok, _run1} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "running",
          config: %{},
          metrics: %{}
        })

      {:ok, _run2} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "completed",
          config: %{},
          metrics: %{}
        })

      assert {:ok, fetched} = ExperimentBackend.get_experiment_with_associations(experiment.id)
      assert fetched.id == experiment.id
      assert length(fetched.training_runs) == 2
    end

    test "returns not_found for non-existent ID" do
      assert {:error, :not_found} = ExperimentBackend.get_experiment_with_associations(99999)
    end
  end

  describe "create_experiment/1" do
    test "creates new experiment with valid attributes" do
      attrs = %{
        name: "New Experiment",
        description: "Test description",
        config: %{dataset: "scifact", model: "llama-3.1-8b"},
        status: "pending"
      }

      assert {:ok, experiment} = ExperimentBackend.create_experiment(attrs)
      assert experiment.name == "New Experiment"
      assert experiment.status == "pending"
    end

    test "returns error with invalid attributes" do
      # Name is required
      attrs = %{description: "No name"}

      assert {:error, changeset} = ExperimentBackend.create_experiment(attrs)
      refute changeset.valid?
    end
  end

  describe "update_experiment/2" do
    test "updates experiment status" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test",
          description: "Desc",
          config: %{},
          status: "pending"
        })

      assert {:ok, updated} =
               ExperimentBackend.update_experiment(experiment.id, %{status: "running"})

      assert updated.status == "running"
    end

    test "returns not_found for non-existent ID" do
      assert {:error, :not_found} =
               ExperimentBackend.update_experiment(99999, %{status: "running"})
    end
  end

  describe "delete_experiment/1" do
    test "deletes experiment" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "To Delete",
          description: "Desc",
          config: %{},
          status: "pending"
        })

      assert {:ok, _deleted} = ExperimentBackend.delete_experiment(experiment.id)
      assert {:error, :not_found} = ExperimentBackend.get_experiment(experiment.id)
    end

    test "returns not_found for non-existent ID" do
      assert {:error, :not_found} = ExperimentBackend.delete_experiment(99999)
    end
  end

  describe "start_experiment/1" do
    test "updates experiment status to running" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test",
          description: "Desc",
          config: %{},
          status: "pending"
        })

      assert {:ok, started} = ExperimentBackend.start_experiment(experiment.id)
      assert started.status == "running"
    end
  end

  describe "complete_experiment/1" do
    test "updates experiment status to completed" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test",
          description: "Desc",
          config: %{},
          status: "running"
        })

      assert {:ok, completed} = ExperimentBackend.complete_experiment(experiment.id)
      assert completed.status == "completed"
    end
  end

  describe "list_runs/2" do
    setup do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test Experiment",
          description: "Desc",
          config: %{},
          status: "pending"
        })

      {:ok, run1} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "running",
          config: %{},
          metrics: %{}
        })

      {:ok, run2} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "completed",
          config: %{},
          metrics: %{}
        })

      %{experiment: experiment, run1: run1, run2: run2}
    end

    test "lists all runs for experiment", %{experiment: experiment, run1: run1, run2: run2} do
      assert {:ok, runs} = ExperimentBackend.list_runs(experiment.id)

      assert length(runs) == 2
      ids = Enum.map(runs, & &1.id)
      assert run1.id in ids
      assert run2.id in ids
    end

    test "filters runs by status", %{experiment: experiment} do
      assert {:ok, runs} = ExperimentBackend.list_runs(experiment.id, status: "completed")

      assert length(runs) == 1
      assert hd(runs).status == "completed"
    end

    test "limits number of runs returned", %{experiment: experiment} do
      assert {:ok, runs} = ExperimentBackend.list_runs(experiment.id, limit: 1)

      assert length(runs) == 1
    end
  end

  describe "get_run/1" do
    test "retrieves run with snapshots" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test",
          description: "Desc",
          config: %{},
          status: "pending"
        })

      {:ok, run} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "running",
          config: %{},
          metrics: %{}
        })

      assert {:ok, fetched} = ExperimentBackend.get_run(run.id)
      assert fetched.id == run.id
    end

    test "returns not_found for non-existent ID" do
      assert {:error, :not_found} = ExperimentBackend.get_run(99999)
    end
  end

  describe "start_run/1" do
    test "updates run status to running" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test",
          description: "Desc",
          config: %{},
          status: "pending"
        })

      {:ok, run} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "pending",
          config: %{},
          metrics: %{}
        })

      assert {:ok, started} = ExperimentBackend.start_run(run.id)
      assert started.status == "running"
    end
  end

  describe "complete_run/1" do
    test "updates run status to completed" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test",
          description: "Desc",
          config: %{},
          status: "pending"
        })

      {:ok, run} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "running",
          config: %{},
          metrics: %{}
        })

      assert {:ok, completed} = ExperimentBackend.complete_run(run.id)
      assert completed.status == "completed"
    end
  end

  describe "list_telemetry_events/2" do
    test "returns empty list (not yet implemented)" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test",
          description: "Desc",
          config: %{},
          status: "pending"
        })

      {:ok, run} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "running",
          config: %{},
          metrics: %{}
        })

      assert {:ok, events} = ExperimentBackend.list_telemetry_events(run.id)
      assert events == []
    end
  end

  describe "get_statistics/1" do
    test "returns run statistics" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test",
          description: "Desc",
          config: %{},
          status: "pending"
        })

      {:ok, run} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "completed",
          lora_config: %{},
          metrics: %{loss: 0.5}
        })

      assert {:ok, stats} = ExperimentBackend.get_statistics(run.id)
      assert stats.run_id == run.id
      assert stats.status == "completed"
      # Duration will be nil since started_at/completed_at don't exist
      assert stats.duration == nil
      assert stats.metrics["loss"] == 0.5
    end

    test "returns experiment statistics when run not found" do
      {:ok, experiment} =
        Experiments.create_experiment(%{
          name: "Test",
          description: "Desc",
          config: %{},
          status: "completed"
        })

      {:ok, _run} =
        Training.create_training_run(%{
          experiment_id: experiment.id,
          status: "completed",
          config: %{},
          metrics: %{}
        })

      assert {:ok, stats} = ExperimentBackend.get_statistics(experiment.id)
      assert stats.experiment_id == experiment.id
      assert stats.total_runs >= 1
      assert stats.completed_runs >= 1
    end
  end

  describe "get_system_statistics/0" do
    test "returns system-wide statistics" do
      # Create some experiments and runs
      {:ok, exp} =
        Experiments.create_experiment(%{
          name: "System Test",
          description: "Desc",
          config: %{},
          status: "running"
        })

      {:ok, _run} =
        Training.create_training_run(%{
          experiment_id: exp.id,
          status: "running",
          config: %{},
          metrics: %{}
        })

      assert {:ok, stats} = ExperimentBackend.get_system_statistics()

      assert Map.has_key?(stats, :experiments)
      assert Map.has_key?(stats, :runs)
      assert Map.has_key?(stats, :last_updated)

      assert stats.experiments.total >= 1
      assert stats.runs.total >= 1
    end
  end

  describe "pubsub_topic/2" do
    test "returns topic for experiment" do
      assert ExperimentBackend.pubsub_topic(:experiment, 123) == "cns:experiment:123"
    end

    test "returns topic for run" do
      assert ExperimentBackend.pubsub_topic(:run, 456) == "cns:run:456"
    end

    test "returns topic for other resources" do
      assert ExperimentBackend.pubsub_topic(:custom, 789) == "cns:custom:789"
    end
  end
end
