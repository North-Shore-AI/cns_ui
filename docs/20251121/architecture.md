# CNS UI Architecture

## Overview

CNS UI is a Phoenix LiveView application that provides a real-time web interface for CNS (Critic-Network Synthesis) dialectical reasoning experiments. The architecture is designed around reactive UI updates, efficient data streaming, and seamless integration with the CNS core library.

### Crucible Alignment

- Training orchestration is delegated to Crucible Framework via `CnsUi.CrucibleClient` (configurable `CRUCIBLE_API_URL`/`CRUCIBLE_API_TOKEN`).
- UI tiles pull styling from shared Crucible UI components so CNS-specific dashboards stay consistent with Crucible UI.
- Run progress can stream from `CRUCIBLE_PUBSUB_NAME` (defaults to `CrucibleUI.PubSub` when co-deployed).

## System Architecture

```
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|   Web Browser    |<--->|    CNS UI        |<--->|    CNS Core      |
|   (LiveView)     |     |    (Phoenix)     |     |    (Library)     |
|                  |     |                  |     |                  |
+------------------+     +--------+---------+     +------------------+
                                 |
                                 v
                         +-------+--------+
                         |                |
                         |   PostgreSQL   |
                         |   (SNOs, Exp)  |
                         |                |
                         +----------------+
```

## Application Layers

### Layer 1: Web Layer (`lib/cns_ui_web/`)

The web layer handles HTTP requests, WebSocket connections, and LiveView rendering.

#### LiveView Components

```
cns_ui_web/
  live/
    dashboard_live.ex           # Main dashboard
    sno_live/
      index.ex                  # SNO list view
      show.ex                   # SNO detail view
      graph.ex                  # SNO graph visualization
    experiment_live/
      index.ex                  # Experiment list
      new.ex                    # Create experiment
      show.ex                   # Experiment detail/progress
      results.ex                # Results analysis
    visualization_live/
      dialectical_flow.ex       # T-A-S flow diagrams
      topology.ex               # Betti number visualizations
      metrics.ex                # Quality metric charts
    citation_live/
      validation.ex             # Citation validation dashboard
      browser.ex                # Citation browser
```

#### Component Hierarchy

```
AppLive (root layout)
  +-- NavComponent
  +-- SidebarComponent
  +-- MainContent
        +-- DashboardLive
        |     +-- MetricsSummaryComponent
        |     +-- RecentExperimentsComponent
        |     +-- QualityTrendsComponent
        |
        +-- SNOLive.Index
        |     +-- SNOListComponent
        |     +-- FilterComponent
        |     +-- SearchComponent
        |
        +-- SNOLive.Show
        |     +-- PropositionTreeComponent
        |     +-- EvidenceChainComponent
        |     +-- ChiralityDisplayComponent
        |
        +-- ExperimentLive.Show
              +-- ProgressBarComponent
              +-- LogStreamComponent
              +-- CheckpointListComponent
```

### Layer 2: Business Logic (`lib/cns_ui/`)

Core business logic and domain models.

```
cns_ui/
  experiments/
    experiment.ex               # Experiment schema
    experiment_config.ex        # Configuration struct
    runner.ex                   # Experiment execution
    checkpoint.ex               # Checkpoint management
  sno/
    sno.ex                      # SNO schema
    proposition.ex              # Proposition schema
    evidence.ex                 # Evidence schema
    parser.ex                   # SNO parsing utilities
  metrics/
    chirality.ex                # Chirality calculations
    topology.ex                 # Betti number metrics
    quality.ex                  # Quality score aggregation
    entailment.ex               # Entailment verification
  citations/
    citation.ex                 # Citation schema
    validator.ex                # Citation validation
    resolver.ex                 # Citation resolution
```

### Layer 3: Data Layer

#### Database Schema

```sql
-- SNOs (Structured Narrative Objects)
CREATE TABLE snos (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content JSONB NOT NULL,
    experiment_id UUID REFERENCES experiments(id),
    chirality_score FLOAT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Propositions within SNOs
CREATE TABLE propositions (
    id UUID PRIMARY KEY,
    sno_id UUID REFERENCES snos(id),
    type VARCHAR(50), -- 'thesis', 'antithesis', 'synthesis'
    content TEXT NOT NULL,
    confidence FLOAT,
    parent_id UUID REFERENCES propositions(id),
    evidence JSONB,
    metadata JSONB
);

-- Experiments
CREATE TABLE experiments (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50),
    config JSONB NOT NULL,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    metrics JSONB,
    checkpoints JSONB[]
);

-- Citations
CREATE TABLE citations (
    id UUID PRIMARY KEY,
    proposition_id UUID REFERENCES propositions(id),
    source_url TEXT,
    source_title TEXT,
    validation_status VARCHAR(50),
    confidence FLOAT,
    last_validated_at TIMESTAMP
);

-- Quality Metrics (time series)
CREATE TABLE quality_metrics (
    id UUID PRIMARY KEY,
    experiment_id UUID REFERENCES experiments(id),
    metric_type VARCHAR(50),
    value FLOAT,
    timestamp TIMESTAMP
);
```

## Integration with CNS Core

### Communication Protocol

CNS UI communicates with CNS Core via:

1. **Direct Function Calls** - When CNS Core is loaded as a dependency
2. **HTTP API** - For distributed deployments
3. **PubSub** - For real-time event streaming

```elixir
# Direct integration
defmodule CnsUi.CoreAdapter do
  def run_synthesis(config) do
    CnsCore.Synthesis.run(config)
  end

  def get_sno(id) do
    CnsCore.SNO.get(id)
  end
end

# Event streaming
defmodule CnsUi.EventHandler do
  use GenServer

  def handle_info({:synthesis_progress, data}, state) do
    Phoenix.PubSub.broadcast(CnsUi.PubSub, "experiment:#{data.id}", {:progress, data})
    {:noreply, state}
  end
end
```

### Real-time Synthesis Visualization

```elixir
defmodule CnsUiWeb.VisualizationLive.DialecticalFlow do
  use CnsUiWeb, :live_view

  def mount(%{"experiment_id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CnsUi.PubSub, "experiment:#{id}")
    end

    {:ok, assign(socket, experiment_id: id, nodes: [], edges: [])}
  end

  def handle_info({:synthesis_step, step}, socket) do
    # Update graph with new dialectical step
    nodes = add_node(socket.assigns.nodes, step)
    edges = add_edges(socket.assigns.edges, step)

    {:noreply, assign(socket, nodes: nodes, edges: edges)}
  end

  def render(assigns) do
    ~H"""
    <div id="dialectical-graph" phx-hook="DialecticalGraph">
      <svg id="graph-svg" viewBox="0 0 800 600">
        <%= for node <- @nodes do %>
          <g class={"node node-#{node.type}"} transform={"translate(#{node.x}, #{node.y})"}>
            <circle r="30" />
            <text><%= node.label %></text>
          </g>
        <% end %>
        <%= for edge <- @edges do %>
          <line x1={edge.x1} y1={edge.y1} x2={edge.x2} y2={edge.y2} />
        <% end %>
      </svg>
    </div>
    """
  end
end
```

## Key Design Patterns

### 1. LiveView State Management

Each LiveView maintains its own state with efficient updates:

```elixir
defmodule CnsUiWeb.SNOLive.Show do
  use CnsUiWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    sno = CnsUi.SNO.get!(id)

    socket =
      socket
      |> assign(:sno, sno)
      |> assign(:active_tab, :overview)
      |> assign(:selected_proposition, nil)

    {:ok, socket}
  end

  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  def handle_event("select_proposition", %{"id" => id}, socket) do
    proposition = Enum.find(socket.assigns.sno.propositions, &(&1.id == id))
    {:noreply, assign(socket, :selected_proposition, proposition)}
  end
end
```

### 2. Component Composition

Reusable components for consistent UI:

```elixir
defmodule CnsUiWeb.Components.MetricCard do
  use Phoenix.Component

  attr :title, :string, required: true
  attr :value, :float, required: true
  attr :trend, :atom, values: [:up, :down, :stable]
  attr :format, :atom, default: :percentage

  def metric_card(assigns) do
    ~H"""
    <div class="metric-card">
      <h3 class="metric-title"><%= @title %></h3>
      <div class="metric-value">
        <%= format_value(@value, @format) %>
        <span class={"trend trend-#{@trend}"}>
          <%= trend_icon(@trend) %>
        </span>
      </div>
    </div>
    """
  end
end
```

### 3. PubSub for Real-time Updates

Efficient event broadcasting:

```elixir
defmodule CnsUi.Experiments.Runner do
  def run(experiment) do
    # Start experiment
    Phoenix.PubSub.broadcast(CnsUi.PubSub, "experiments", {:started, experiment})

    # Stream progress
    Stream.each(steps, fn step ->
      Phoenix.PubSub.broadcast(
        CnsUi.PubSub,
        "experiment:#{experiment.id}",
        {:step_completed, step}
      )
    end)

    # Complete
    Phoenix.PubSub.broadcast(CnsUi.PubSub, "experiments", {:completed, experiment})
  end
end
```

## Performance Considerations

### 1. Efficient Graph Rendering

For large dialectical graphs (1000+ nodes):

- Virtual scrolling for node lists
- WebGL-based rendering via hooks
- Incremental updates (only changed nodes)
- Level-of-detail rendering (collapse distant clusters)

### 2. Database Optimization

- Indexes on `sno_id`, `experiment_id`, `type`
- JSONB GIN indexes for content search
- Partitioned tables for time-series metrics
- Connection pooling via DBConnection

### 3. LiveView Optimization

- Temporary assigns for large lists
- Stream-based collections for infinite scroll
- Debounced search inputs
- Lazy loading for tabs and sections

## Security Model

### Authentication

- Phoenix.Token for session management
- Optional OAuth2 integration
- API key authentication for programmatic access

### Authorization

- Role-based access control (RBAC)
- Experiment ownership
- Read-only sharing capabilities

## Deployment Architecture

### Single Node

```
+------------------+
|   CNS UI App     |
|   - Phoenix      |
|   - CNS Core     |
|   - PostgreSQL   |
+------------------+
```

### Distributed

```
+--------+     +--------+     +--------+
|  Node  |     |  Node  |     |  Node  |
| (UI 1) |     | (UI 2) |     | (Core) |
+---+----+     +---+----+     +---+----+
    |              |              |
    +------+-------+------+-------+
           |              |
      +----+----+    +----+----+
      |   PG   |    |  Redis  |
      | Primary|    | PubSub  |
      +--------+    +---------+
```

## Testing Strategy

### Unit Tests

- Context modules (Experiments, SNO, Metrics)
- Schema validations
- Business logic functions

### LiveView Tests

- Component rendering
- Event handling
- Socket state changes

### Integration Tests

- Full user workflows
- CNS Core integration
- Database operations

```elixir
defmodule CnsUiWeb.SNOLiveTest do
  use CnsUiWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "displays SNO details", %{conn: conn} do
    sno = insert(:sno)
    {:ok, view, _html} = live(conn, ~p"/snos/#{sno.id}")

    assert has_element?(view, "#sno-title", sno.title)
    assert has_element?(view, ".chirality-score")
  end
end
```

## Future Considerations

1. **WebAssembly Integration** - Client-side computation for complex visualizations
2. **GraphQL API** - Flexible querying for external tools
3. **Collaborative Editing** - Real-time multi-user SNO editing
4. **Plugin System** - Custom visualization and analysis plugins
5. **Mobile Support** - Responsive design and PWA capabilities
