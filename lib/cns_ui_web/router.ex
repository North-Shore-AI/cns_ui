defmodule CnsUiWeb.Router do
  @moduledoc """
  CNS UI main router with composable feature mounting.

  Integrates:
  - CNS-specific LiveViews (SNOs, experiments, dialectical components)
  - Ingot labeling UI for SNO annotation
  - Crucible UI for experiment dashboards
  """

  use CnsUiWeb, :router
  import Ingot.Labeling.Router
  import Crucible.UI.Router

  # ============================================================================
  # Pipelines
  # ============================================================================

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CnsUiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # ============================================================================
  # CNS UI Native Routes
  # ============================================================================
  # These routes are implemented directly in cns_ui for CNS-specific features
  # that don't fit into composable libraries.

  scope "/", CnsUiWeb do
    pipe_through :browser

    # Dashboard - Main entry point showing system overview
    live "/", DashboardLive, :index

    # SNO Management - CRUD operations for Structured Narrative Objects
    live "/snos", SNOLive.Index, :index
    live "/snos/:id", SNOLive.Show, :show

    # Experiment Management - CNS-specific experiment UI
    # Note: Crucible UI also provides experiment routes at /crucible/experiments
    live "/experiments", ExperimentLive.Index, :index
    live "/experiments/new", ExperimentLive.Index, :new
    live "/experiments/:id", ExperimentLive.Show, :show
    live "/experiments/:id/edit", ExperimentLive.Show, :edit

    # CNS 3.0 Agent-Specific Views - Dialectical reasoning components
    # SNO graph topology visualization
    live "/graph", GraphLive, :index
    # Proposer agent monitoring
    live "/proposer", ProposerLive, :index
    # Antagonist agent monitoring
    live "/antagonist", AntagonistLive, :index
    # Synthesizer agent monitoring
    live "/synthesizer", SynthesizerLive, :index

    # Training & Metrics - Model training and quality tracking
    # Training job submission
    live "/training", TrainingLive, :index
    # Individual run monitoring
    live "/runs/:id", RunLive, :show
    # Aggregate quality metrics
    live "/metrics", MetricsLive, :index
    # Visualization overlay controls
    live "/overlay", OverlayLive, :index
  end

  # ============================================================================
  # Ingot Labeling Routes (Composable UI)
  # ============================================================================
  # Mounted at /labeling for SNO annotation workflows.
  #
  # Backend: CnsUi.LabelingBackend (lib/cns_ui/labeling_backend.ex)
  # - Implements Ingot.Labeling.Backend behaviour
  # - Provides three annotation queues:
  #   1. sno_validation - Validate Proposer output (grounding, citations)
  #   2. antagonist_review - Review contradiction flags (future)
  #   3. synthesis_verification - Verify synthesis quality (future)
  #
  # Routes provided:
  # - GET /labeling/queue/:queue_id - Queue dashboard
  # - GET /labeling/assignment/:id - Label assignment view
  # - POST /labeling/labels - Submit label

  scope "/" do
    pipe_through :browser

    labeling_routes("/labeling",
      root_layout: {CnsUiWeb.Layouts, :root},
      config: %{
        backend: CnsUi.LabelingBackend,
        mode: :sno_annotation
      }
    )
  end

  # ============================================================================
  # Crucible UI Experiment Routes (Composable UI)
  # ============================================================================
  # Mounted at /crucible/experiments for experiment management dashboards.
  #
  # Backend: CnsUi.ExperimentBackend (lib/cns_ui/experiment_backend.ex)
  # - Implements Crucible.UI.Backend behaviour
  # - Wraps CnsUi.Experiments and CnsUi.Training contexts
  # - Emits telemetry events for monitoring
  # - Provides PubSub topics: cns:experiment:{id}, cns:run:{id}
  #
  # Routes provided:
  # - GET /crucible/experiments - List all experiments
  # - GET /crucible/experiments/:id - Experiment detail view
  # - GET /crucible/experiments/:id/runs - Experiment runs list
  # - GET /crucible/experiments/runs/:id - Individual run view
  #
  # Note: This complements the native /experiments routes above.
  # Use native routes for CNS-specific experiment creation/editing,
  # use Crucible routes for standardized experiment monitoring.

  scope "/" do
    pipe_through :browser

    experiment_routes("/crucible/experiments",
      root_layout: {CnsUiWeb.Layouts, :root},
      backend: CnsUi.ExperimentBackend
    )
  end

  # ============================================================================
  # Development Tools
  # ============================================================================

  # Enable LiveDashboard in development for debugging
  if Application.compile_env(:cns_ui, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CnsUiWeb.Telemetry
    end
  end
end
