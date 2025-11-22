defmodule CnsUi.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/North-Shore-AI/cns_ui"

  def project do
    [
      app: :cns_ui,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Hex publishing
      description: description(),
      package: package(),
      docs: docs(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Dialyzer
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  def application do
    [
      mod: {CnsUi.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix core
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 0.20.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:heroicons, "~> 0.5"},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.5"},

      # CNS ecosystem
      {:crucible_ui, path: "../crucible_ui"},
      {:cns, path: "../cns"},

      # Development and testing
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:ex_machina, "~> 2.7", only: :test},
      {:faker, "~> 0.17", only: :test},

      # Utilities
      {:nimble_csv, "~> 1.2"},
      {:decimal, "~> 2.0"},
      {:timex, "~> 3.7"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end

  defp description do
    """
    Phoenix LiveView interface for CNS (Critic-Network Synthesis) dialectical reasoning experiments.
    Provides comprehensive visualization of thesis-antithesis-synthesis flows, evidence grounding
    analysis, and training experiment management.
    """
  end

  defp package do
    [
      name: "cns_ui",
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      maintainers: ["North-Shore-AI"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "CNS UI",
      source_ref: "v#{@version}",
      source_url: @source_url,
      canonical: "https://hexdocs.pm/cns_ui",
      extras: [
        "README.md",
        "LICENSE",
        "docs/20251121/architecture.md",
        "docs/20251121/features.md",
        "docs/20251121/visualization_guide.md",
        "docs/20251121/experiment_workflow.md"
      ],
      groups_for_modules: [
        "Core Contexts": [
          CnsUi.SNOs,
          CnsUi.Experiments,
          CnsUi.Training,
          CnsUi.Citations,
          CnsUi.Challenges,
          CnsUi.Metrics
        ],
        LiveView: [
          CnsUiWeb.DashboardLive,
          CnsUiWeb.SNOLive.Index,
          CnsUiWeb.SNOLive.Show,
          CnsUiWeb.GraphLive,
          CnsUiWeb.ProposerLive,
          CnsUiWeb.AntagonistLive,
          CnsUiWeb.SynthesizerLive,
          CnsUiWeb.TrainingLive,
          CnsUiWeb.MetricsLive,
          CnsUiWeb.ExperimentLive.Index,
          CnsUiWeb.ExperimentLive.Show
        ],
        Components: [
          CnsUiWeb.Components.ChiralityGauge,
          CnsUiWeb.Components.EntailmentMeter,
          CnsUiWeb.Components.TopologyGraph,
          CnsUiWeb.Components.EvidenceTree
        ]
      ]
    ]
  end
end
