# CNS UI

[![CI](https://github.com/North-Shore-AI/cns_ui/actions/workflows/ci.yml/badge.svg)](https://github.com/North-Shore-AI/cns_ui/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/cns_ui.svg)](https://hex.pm/packages/cns_ui)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/cns_ui)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

**Phoenix LiveView interface for CNS (Critic-Network Synthesis) dialectical reasoning experiments.**

CNS UI provides a comprehensive web-based dashboard for managing, visualizing, and analyzing dialectical reasoning processes. Built on Phoenix LiveView, it offers real-time visualization of thesis-antithesis-synthesis flows, evidence grounding analysis, and training experiment management.

## Features

### Dialectical Reasoning Visualization
- Interactive thesis-antithesis-synthesis flow diagrams
- Real-time rendering of dialectical graph structures
- Visual representation of proposition relationships
- Animated synthesis emergence displays

### SNO (Structured Narrative Object) Explorer
- Hierarchical SNO browser with search and filtering
- Detailed SNO inspection views
- Proposition-level drill-down capabilities
- Evidence chain visualization
- Citation cross-referencing

### Evidence Grounding Displays
- Source document linking
- Citation validation status indicators
- Confidence score overlays
- Provenance tracking visualization

### Chirality and Topology Metrics
- Chirality score dashboards with historical trends
- Fisher-Rao metric displays
- Betti number (topology) visualizations
- Geometric invariant tracking
- Interactive metric exploration

### Training Experiment Management
- Dataset upload and configuration
- Model parameter configuration UI
- Training progress monitoring
- Checkpoint management
- Result comparison tools

### Citation Validation Dashboards
- Automated citation verification status
- Source reliability scoring
- Dead link detection
- Citation completeness metrics
- Batch validation tools

### Quality Metrics
- Entailment verification scores
- Pass rate tracking across experiments
- Consistency metrics
- Temporal quality trends
- Export and reporting capabilities

## Screenshots

*Screenshots coming soon*

## Installation

Add `cns_ui` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cns_ui, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
mix ecto.setup
```

## Configuration

Configure CNS UI in your `config/config.exs`:

```elixir
config :cns_ui,
  # CNS core library connection
  cns_core_endpoint: "http://localhost:4001",

  # Database configuration
  database_url: System.get_env("DATABASE_URL"),

  # Visualization settings
  max_graph_nodes: 1000,
  default_layout: :hierarchical,

  # Experiment settings
  checkpoint_dir: "priv/checkpoints",
  max_concurrent_experiments: 3
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection URL | `postgres://localhost/cns_ui_dev` |
| `SECRET_KEY_BASE` | Phoenix secret key | Generated |
| `CNS_CORE_URL` | CNS core library endpoint | `http://localhost:4001` |
| `PHX_HOST` | Application host | `localhost` |
| `PORT` | Application port | `4000` |

## Development

### Prerequisites

- Elixir 1.14+
- Erlang/OTP 25+
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)

### Setup

```bash
# Clone the repository
git clone https://github.com/North-Shore-AI/cns_ui.git
cd cns_ui

# Install dependencies
mix deps.get

# Setup database
mix ecto.setup

# Install Node.js dependencies
cd assets && npm install && cd ..

# Start Phoenix server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) in your browser.

### Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/cns_ui_web/live/sno_live_test.exs
```

### Code Quality

```bash
# Format code
mix format

# Run Credo for static analysis
mix credo --strict

# Run Dialyzer for type checking
mix dialyzer
```

## Architecture

CNS UI follows a layered Phoenix LiveView architecture:

```
lib/
  cns_ui/           # Core business logic
    experiments/    # Experiment management
    sno/            # SNO data structures
    metrics/        # Quality metrics
  cns_ui_web/       # Web layer
    live/           # LiveView components
      dashboard/    # Main dashboard views
      sno/          # SNO explorer views
      experiments/  # Experiment management views
      visualization/ # Graph and chart components
    components/     # Reusable UI components
```

For detailed architecture documentation, see [docs/20251121/architecture.md](docs/20251121/architecture.md).

## Documentation

- [Architecture Overview](docs/20251121/architecture.md)
- [Feature Specifications](docs/20251121/features.md)
- [Visualization Guide](docs/20251121/visualization_guide.md)
- [Experiment Workflow](docs/20251121/experiment_workflow.md)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code:
- Passes all tests
- Follows the existing code style
- Includes appropriate documentation
- Has zero compilation warnings

## License

Copyright 2024-2025 North-Shore-AI

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Acknowledgments

- Built on [Phoenix Framework](https://phoenixframework.org/)
- Part of the [North-Shore-AI](https://github.com/North-Shore-AI) research ecosystem
- Integrates with [Crucible Framework](https://github.com/North-Shore-AI/crucible_framework) for experiment orchestration
