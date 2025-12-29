# CnsUi.LabelingBackend

Backend implementation for CNS SNO annotation queues with dual-mode support (local + Anvil).

## Quick Start

### Local Mode (Development)

```elixir
# Uses CnsUi.SNOs context directly
Application.put_env(:cns_ui, :labeling_mode, :local)

{:ok, assignment} = CnsUi.LabelingBackend.get_next_assignment("sno_validation", "user123")
```

### Anvil Mode (Production)

```bash
# Set environment variables
export LABELING_MODE=anvil
export ANVIL_URL=http://anvil:4101
export ANVIL_TENANT_ID=cns_ui

mix phx.server
```

## Modules

- `CnsUi.LabelingBackend` - Main backend implementation (implements `Ingot.Labeling.Backend`)
- `CnsUi.LabelingBackend.QueueConfig` - Queue definitions and schemas for CNS annotation queues

## Queues

| Queue ID | Purpose | Agent | Status |
|----------|---------|-------|--------|
| `sno_validation` | Validate Proposer output | Proposer | Active |
| `antagonist_review` | Review contradiction flags | Antagonist | Future |
| `synthesis_verification` | Verify synthesis quality | Synthesizer | Future |

## Configuration

See [ANVIL_INTEGRATION.md](../../docs/ANVIL_INTEGRATION.md) for full configuration guide.

## Testing

```bash
mix test test/cns_ui/labeling_backend_test.exs
```

All tests use local mode by default.
