# Anvil Integration Guide

This document explains how to wire up CnsUi.LabelingBackend to real Anvil endpoints for distributed SNO annotation.

## Overview

CnsUi.LabelingBackend now supports two modes:

1. **Local Mode** (default) - Uses CnsUi.SNOs context directly, stores labels in local database
2. **Anvil Mode** - Delegates to Ingot.AnvilClient for distributed queue management via Anvil HTTP API

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CnsUi.LabelingBackend                   │
│                                                             │
│  ┌─────────────┐                    ┌─────────────────┐   │
│  │ Local Mode  │                    │  Anvil Mode     │   │
│  │             │                    │                 │   │
│  │  CnsUi.SNOs │                    │ AnvilClient     │   │
│  │  (Ecto)     │                    │  (HTTP/Elixir)  │   │
│  └─────────────┘                    └─────────────────┘   │
│                                              │             │
└──────────────────────────────────────────────┼─────────────┘
                                               │
                                               ▼
                                    ┌─────────────────────┐
                                    │  Anvil Service      │
                                    │  (HTTP API)         │
                                    │  Port: 4101         │
                                    └─────────────────────┘
```

## Configuration

### Development (Local Mode)

Default configuration uses local mode:

```elixir
# config/config.exs
config :cns_ui, :labeling_mode, :local
```

### Production (Anvil Mode)

Enable Anvil mode via environment variables:

```bash
# Set labeling mode to Anvil
export LABELING_MODE=anvil

# Configure Anvil endpoint
export ANVIL_URL=http://anvil.research.svc.cluster.local:4101
export ANVIL_TENANT_ID=cns_ui

# Start application
mix phx.server
```

Or configure in `config/runtime.exs`:

```elixir
config :cns_ui, :labeling_mode, :anvil

config :ingot,
  anvil_client_adapter: Ingot.AnvilClient.HTTPAdapter,
  anvil_base_url: "http://anvil-service:4101",
  default_tenant_id: "cns_ui"
```

## Queue Configuration

Three CNS annotation queues are configured in `CnsUi.LabelingBackend.QueueConfig`:

### 1. SNO Validation (`sno_validation`)

**Purpose:** Validate Proposer agent output

**Schema Fields:**
- `validation` (select, required): accept / reject / needs_review
- `citation_valid` (boolean): Do citations exist and support claim?
- `entailment_score` (scale 0-1): Estimated entailment between claim and evidence
- `issues` (multiselect): hallucinated_citation, weak_entailment, schema_invalid, etc.
- `notes` (text): Additional notes

**Success Criteria:**
- Citation accuracy: 96%
- Entailment threshold: 0.75
- Schema compliance: 100%

### 2. Antagonist Review (`antagonist_review`)

**Purpose:** Review Antagonist agent contradiction flags

**Schema Fields:**
- `verdict` (select, required): confirm_contradiction / false_positive / needs_expert
- `contradiction_type` (select): direct_negation, temporal, scope, interpretation
- `beta1_valid` (boolean): Does β₁ score reflect topological gap?
- `severity` (select): low, medium, high, critical
- `notes` (text): Reasoning for verdict

**Success Criteria:**
- Precision: 80%
- Recall: 70%
- β₁ accuracy: 90%

### 3. Synthesis Verification (`synthesis_verification`)

**Purpose:** Verify Synthesizer agent output quality

**Schema Fields:**
- `verdict` (select, required): accept / reject / needs_revision
- `beta1_reduced` (boolean): ≥30% β₁ reduction achieved?
- `critics_passed` (boolean): All critics pass thresholds?
- `provenance_intact` (boolean): Provenance chain preserved?
- `issues` (multiselect): hallucinated_synthesis, weak_integration, etc.
- `notes` (text): Detailed feedback

**Success Criteria:**
- β₁ reduction: ≥30%
- Critic pass rate: 100%
- Provenance preserved: 100%

## API Usage

### Get Next Assignment

```elixir
# Local mode - uses CnsUi.SNOs
{:ok, assignment} = CnsUi.LabelingBackend.get_next_assignment("sno_validation", "user123")

# Anvil mode - calls Ingot.AnvilClient.get_next_assignment
{:ok, assignment} = CnsUi.LabelingBackend.get_next_assignment("sno_validation", "user123")
# => Makes HTTP GET to http://anvil:4101/v1/queues/sno_validation/assignments/next?user_id=user123
```

### Submit Label

```elixir
label_data = %{
  values: %{"validation" => "accept", "notes" => "Citation checks out"},
  user_id: "user123",
  time_spent_ms: 45000
}

# Local mode - updates SNO in database
{:ok, label} = CnsUi.LabelingBackend.submit_label("sno_validation:42", label_data)

# Anvil mode - posts to Anvil + updates local SNO
{:ok, label} = CnsUi.LabelingBackend.submit_label("sno_validation:42", label_data)
# => Makes HTTP POST to http://anvil:4101/v1/labels
# => Also updates local SNO status for consistency
```

### Get Queue Stats

```elixir
# Local mode - queries CnsUi.SNOs
{:ok, stats} = CnsUi.LabelingBackend.get_queue_stats("sno_validation")
# => %{total: 100, pending: 20, validated: 70, rejected: 10, remaining: 20}

# Anvil mode - calls Anvil API
{:ok, stats} = CnsUi.LabelingBackend.get_queue_stats("sno_validation")
# => Makes HTTP GET to http://anvil:4101/v1/queues/sno_validation
```

## Dual-Mode Behavior

### Local Mode
- **Assignments:** Fetches from `snos` table via `CnsUi.SNOs.list_snos(status: "pending")`
- **Labels:** Stores in `snos` metadata, updates status directly
- **Stats:** Aggregates from `CnsUi.SNOs.count_by_status()`

### Anvil Mode
- **Assignments:** HTTP GET to Anvil `/v1/queues/:queue_id/assignments/next`
- **Labels:** HTTP POST to Anvil `/v1/labels` + local SNO update for consistency
- **Stats:** HTTP GET to Anvil `/v1/queues/:queue_id`
- **Tenant Headers:** Adds `x-tenant-id: cns_ui` to all requests

## Testing

Tests always use **local mode** to avoid external dependencies:

```elixir
# config/test.exs
config :cns_ui, :labeling_mode, :local

config :ingot,
  anvil_client_adapter: Ingot.AnvilClient.MockAdapter,
  anvil_base_url: "http://localhost:4101",
  default_tenant_id: "cns_ui"
```

Run tests:

```bash
mix test test/cns_ui/labeling_backend_test.exs
```

## Deployment

### Docker Compose

```yaml
services:
  cns_ui:
    image: cns_ui:latest
    environment:
      - LABELING_MODE=anvil
      - ANVIL_URL=http://anvil:4101
      - ANVIL_TENANT_ID=cns_ui
    depends_on:
      - anvil
      - postgres

  anvil:
    image: anvil:latest
    ports:
      - "4101:4101"
    environment:
      - DATABASE_URL=ecto://postgres:postgres@postgres/anvil
```

### Kubernetes

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cns-ui-config
data:
  LABELING_MODE: "anvil"
  ANVIL_URL: "http://anvil.research.svc.cluster.local:4101"
  ANVIL_TENANT_ID: "cns_ui"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cns-ui
spec:
  template:
    spec:
      containers:
      - name: cns-ui
        image: cns_ui:latest
        envFrom:
        - configMapRef:
            name: cns-ui-config
```

## Troubleshooting

### Check Current Mode

```elixir
iex> Application.get_env(:cns_ui, :labeling_mode)
:local  # or :anvil
```

### Test Anvil Connection

```elixir
iex> Ingot.AnvilClient.health_check()
{:ok, :healthy}
```

### Debug HTTP Requests

Enable logging:

```elixir
# config/dev.exs
config :logger, level: :debug
```

Watch for Anvil HTTP calls:

```
[debug] Fetching assignment from Anvil: queue=sno_validation, user=user123
[debug] Submitting label to Anvil: assignment=sno_validation:42
```

### Common Issues

**Issue:** `{:error, :not_available}`

**Cause:** Anvil mode enabled but HTTPoison not available

**Fix:** Add HTTPoison to dependencies:

```elixir
# mix.exs
{:httpoison, "~> 2.0"}
```

**Issue:** `{:error, {:unexpected, :timeout}}`

**Cause:** Anvil service unreachable

**Fix:** Check Anvil service is running and URL is correct:

```bash
curl http://anvil:4101/health
```

**Issue:** Labels submitted to Anvil but local SNO not updated

**Cause:** Expected behavior - Anvil mode updates local SNO asynchronously

**Fix:** Check `update_local_sno_from_label/2` logs for errors

## Future Enhancements

### Planned Features

1. **Hybrid Mode** - Use Anvil for queue management, local database for label storage
2. **Queue Sync** - Periodic sync of Anvil queue state to local cache
3. **Retry Logic** - Automatic retry for failed Anvil API calls
4. **Batch Operations** - Submit multiple labels in single HTTP request
5. **Inter-Rater Reliability** - User-aware assignment to prevent duplicate labeling

### Configuration API

Future: Dynamic mode switching via API:

```elixir
CnsUi.LabelingBackend.set_mode(:anvil)
CnsUi.LabelingBackend.set_anvil_config(url: "...", tenant_id: "...")
```

## References

- [Ingot README](https://github.com/North-Shore-AI/ingot/blob/main/README.md)
- [Anvil API Documentation](https://github.com/North-Shore-AI/anvil)
- [LabelingIR Specification](https://github.com/North-Shore-AI/labeling_ir)
- [CNS 3.0 Agent Playbook](../../../tinkerer/CLAUDE.md)
