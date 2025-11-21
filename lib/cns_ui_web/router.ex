defmodule CnsUiWeb.Router do
  use CnsUiWeb, :router

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

  scope "/", CnsUiWeb do
    pipe_through :browser

    live "/", DashboardLive, :index

    # SNO routes
    live "/snos", SNOLive.Index, :index
    live "/snos/:id", SNOLive.Show, :show

    # Experiment routes
    live "/experiments", ExperimentLive.Index, :index
    live "/experiments/new", ExperimentLive.Index, :new
    live "/experiments/:id", ExperimentLive.Show, :show
    live "/experiments/:id/edit", ExperimentLive.Show, :edit

    # Component-specific routes
    live "/graph", GraphLive, :index
    live "/proposer", ProposerLive, :index
    live "/antagonist", AntagonistLive, :index
    live "/synthesizer", SynthesizerLive, :index
    live "/training", TrainingLive, :index
    live "/metrics", MetricsLive, :index
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:cns_ui, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CnsUiWeb.Telemetry
    end
  end
end
