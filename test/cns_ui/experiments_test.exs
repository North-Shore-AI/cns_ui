defmodule CnsUi.ExperimentsTest do
  use CnsUi.DataCase

  alias CnsUi.Experiments
  alias CnsUi.Experiments.Experiment

  import CnsUi.ExperimentsFixtures

  describe "experiments" do
    test "list_experiments/0 returns all experiments" do
      experiment = experiment_fixture()
      assert Experiments.list_experiments() == [experiment]
    end

    test "get_experiment!/1 returns the experiment with given id" do
      experiment = experiment_fixture()
      assert Experiments.get_experiment!(experiment.id) == experiment
    end

    test "create_experiment/1 with valid data creates an experiment" do
      valid_attrs = %{name: "Test experiment", description: "Test", status: "pending"}

      assert {:ok, %Experiment{} = experiment} = Experiments.create_experiment(valid_attrs)
      assert experiment.name == "Test experiment"
      assert experiment.status == "pending"
    end

    test "create_experiment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Experiments.create_experiment(%{name: nil})
    end

    test "create_experiment/1 validates status values" do
      assert {:error, changeset} =
               Experiments.create_experiment(%{name: "Test", status: "invalid"})

      assert "is invalid" in errors_on(changeset).status
    end

    test "create_experiment/1 enforces unique names" do
      experiment_fixture(%{name: "unique_name"})
      assert {:error, changeset} = Experiments.create_experiment(%{name: "unique_name"})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "update_experiment/2 with valid data updates the experiment" do
      experiment = experiment_fixture()
      update_attrs = %{status: "running"}

      assert {:ok, %Experiment{} = updated} =
               Experiments.update_experiment(experiment, update_attrs)

      assert updated.status == "running"
    end

    test "delete_experiment/1 deletes the experiment" do
      experiment = experiment_fixture()
      assert {:ok, %Experiment{}} = Experiments.delete_experiment(experiment)
      assert_raise Ecto.NoResultsError, fn -> Experiments.get_experiment!(experiment.id) end
    end

    test "change_experiment/1 returns an experiment changeset" do
      experiment = experiment_fixture()
      assert %Ecto.Changeset{} = Experiments.change_experiment(experiment)
    end

    test "active_experiments/0 returns only running experiments" do
      pending = experiment_fixture(%{status: "pending"})
      running = experiment_fixture(%{status: "running"})

      result = Experiments.active_experiments()
      assert running in result
      refute pending in result
    end

    test "count_by_status/0 returns counts by status" do
      experiment_fixture(%{status: "pending"})
      experiment_fixture(%{status: "running"})
      experiment_fixture(%{status: "running"})

      counts = Experiments.count_by_status()
      assert counts["pending"] == 1
      assert counts["running"] == 2
    end
  end
end
