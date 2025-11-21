# CNS Experiment Workflow

## Overview

This guide walks through the complete workflow for running CNS dialectical reasoning experiments, from dataset preparation to result analysis and reporting.

---

## 1. Dataset Upload

### Supported Dataset Formats

| Format | Extension | Description |
|--------|-----------|-------------|
| JSON Lines | `.jsonl` | One JSON object per line |
| CSV | `.csv` | Comma-separated values |
| Parquet | `.parquet` | Columnar storage format |
| JSON | `.json` | Array of objects |

### Required Fields

For dialectical training data:

```json
{
  "id": "unique-identifier",
  "thesis": "The initial proposition or claim",
  "antithesis": "The opposing proposition or counter-argument",
  "synthesis": "The resolved or integrated proposition",
  "evidence": [
    {
      "text": "Supporting evidence text",
      "source": "Source citation",
      "confidence": 0.95
    }
  ],
  "metadata": {
    "domain": "philosophy",
    "difficulty": "medium"
  }
}
```

### Upload Process

1. **Navigate to Datasets**
   - Go to Dashboard > Datasets > Upload

2. **Select Files**
   - Drag and drop or click to browse
   - Maximum file size: 1GB
   - Multiple files supported

3. **Configure Import**
   - Field mapping (if column names differ)
   - Encoding (UTF-8 default)
   - Delimiter (for CSV)

4. **Validate**
   - CNS UI validates schema
   - Preview first 100 rows
   - View validation errors

5. **Import**
   - Click "Import Dataset"
   - Monitor progress bar
   - View import summary

### Dataset Management

After upload:

- **Preview**: View sample data
- **Statistics**: Row count, field distribution
- **Quality Check**: Automated quality analysis
- **Versioning**: Track dataset versions
- **Delete**: Remove dataset

---

## 2. Model Configuration

### Configuration Wizard

#### Step 1: Experiment Basics

```yaml
name: "CNS Training Experiment 001"
description: "Training proposer model on philosophy dataset"
tags:
  - philosophy
  - dialectics
  - v1
priority: normal  # low, normal, high, critical
```

#### Step 2: Model Selection

**Model Types:**

| Type | Purpose | Description |
|------|---------|-------------|
| Proposer | Generate theses | Creates initial propositions |
| Antagonist | Generate antitheses | Creates counter-arguments |
| Synthesizer | Generate syntheses | Integrates thesis and antithesis |

**Base Models:**

- `gpt-4-turbo` - High quality, slower
- `gpt-3.5-turbo` - Faster, good quality
- `claude-3-sonnet` - Balanced
- `llama-3-70b` - Open source
- Custom fine-tuned models

#### Step 3: Hyperparameters

```yaml
training:
  learning_rate: 0.0001
  batch_size: 32
  epochs: 10
  warmup_steps: 500
  weight_decay: 0.01

  # Optimization
  optimizer: "adamw"
  scheduler: "cosine"
  gradient_accumulation: 4
  mixed_precision: true

  # Regularization
  dropout: 0.1
  label_smoothing: 0.1
```

#### Step 4: Dataset Configuration

```yaml
dataset:
  name: "philosophy-dialectics-v2"
  split:
    train: 0.8
    validation: 0.1
    test: 0.1

  # Sampling
  shuffle: true
  seed: 42
  max_samples: null  # null for all

  # Augmentation
  augmentation:
    enabled: true
    techniques:
      - paraphrase
      - backtranslation
```

#### Step 5: Evaluation Configuration

```yaml
evaluation:
  frequency: 1000  # steps
  metrics:
    - entailment_score
    - chirality
    - grounding_score
    - bleu
    - rouge

  # Baselines
  compare_to:
    - "baseline-model-v1"
    - "previous-best"

  # Early stopping
  early_stopping:
    enabled: true
    metric: "entailment_score"
    patience: 3
    min_delta: 0.001
```

#### Step 6: Resource Allocation

```yaml
resources:
  gpu:
    count: 2
    type: "A100"
  memory: "64GB"

  limits:
    max_runtime: "24h"
    max_cost: 100.0  # USD

  scheduling:
    start_immediately: true
    # Or schedule:
    # start_at: "2024-01-15T02:00:00Z"
```

### Configuration Templates

Save configurations as templates for reuse:

- **Quick Test** - Small batch, 1 epoch, fast feedback
- **Standard Training** - Balanced settings
- **Production Training** - Full dataset, many epochs
- **Hyperparameter Search** - Grid/random search

---

## 3. Training Execution

### Starting Training

1. **Review Configuration**
   - Final configuration summary
   - Estimated time and cost
   - Resource requirements

2. **Launch**
   - Click "Start Experiment"
   - Experiment queued or started

3. **Monitor Status**
   - Status: Queued > Starting > Running > Complete
   - Estimated time remaining
   - Queue position (if queued)

### Training Dashboard

#### Progress Panel

- **Overall Progress** - Epoch X of Y, Step N of M
- **Current Batch** - Processing batch details
- **Speed** - Steps/second, samples/second
- **ETA** - Estimated completion time

#### Loss Curves

Real-time charts showing:

- Training loss
- Validation loss
- Learning rate
- Gradient norm

#### Metric Curves

- Entailment score over time
- Chirality over time
- Custom metrics

#### Resource Monitor

- GPU utilization (%)
- GPU memory usage
- CPU utilization
- System memory

### Log Viewer

Real-time streaming logs with:

- Timestamp
- Log level (DEBUG, INFO, WARN, ERROR)
- Message
- Searchable
- Filterable
- Downloadable

### Actions During Training

| Action | Description |
|--------|-------------|
| Pause | Temporarily pause training |
| Resume | Resume paused training |
| Stop | Gracefully stop with checkpoint |
| Cancel | Immediately terminate |
| Adjust LR | Modify learning rate |
| Save Checkpoint | Manual checkpoint |

---

## 4. Result Analysis

### Experiment Results Page

After training completes:

#### Summary Tab

- **Final Metrics** - All evaluation metrics
- **Training Summary** - Duration, samples processed
- **Best Checkpoint** - Highest performing
- **Configuration Used** - Full configuration reference

#### Metrics Tab

**Metric Table:**

| Metric | Final | Best | Baseline | Delta |
|--------|-------|------|----------|-------|
| Entailment | 0.847 | 0.851 | 0.792 | +7.4% |
| Chirality | 0.042 | 0.038 | 0.089 | -52.8% |
| Grounding | 0.823 | 0.831 | 0.756 | +9.9% |

**Charts:**

- Learning curves
- Metric progression
- Distribution shifts
- Confusion matrices

#### Checkpoints Tab

List of saved checkpoints:

| Checkpoint | Step | Entailment | Size | Actions |
|------------|------|------------|------|---------|
| best | 15000 | 0.851 | 2.3GB | Load, Download, Deploy |
| epoch-5 | 12500 | 0.839 | 2.3GB | Load, Download |
| epoch-3 | 7500 | 0.812 | 2.3GB | Load, Download |

#### Samples Tab

Inspect model outputs:

- Input thesis/antithesis pairs
- Generated synthesis
- Ground truth comparison
- Metric scores per sample
- Filter by score range

#### Comparison Tab

Compare with other experiments:

- Side-by-side metrics
- Statistical significance tests
- Visualization overlays

### Analysis Tools

#### Failure Analysis

Identify and categorize failures:

1. **High-Error Samples** - Worst performing
2. **Error Categories** - Cluster by failure type
3. **Error Trends** - Patterns in failures

#### Feature Attribution

Understand model decisions:

- Attention visualization
- Important input tokens
- Decision pathways

---

## 5. Export and Reporting

### Export Options

#### Model Export

- **Full Model** - Complete trained model
- **Weights Only** - Model weights for fine-tuning
- **ONNX** - Cross-platform deployment
- **TensorRT** - Optimized inference

#### Data Export

- **Results CSV** - All metrics and samples
- **Predictions** - Model outputs for test set
- **Embeddings** - Vector representations

### Report Generation

#### Report Types

1. **Experiment Summary**
   - Configuration
   - Key metrics
   - Learning curves
   - Sample outputs

2. **Comparison Report**
   - Multi-experiment comparison
   - Statistical tests
   - Winner determination

3. **Publication Report**
   - LaTeX-formatted tables
   - Publication-ready figures
   - Method description

#### Report Formats

| Format | Extension | Use Case |
|--------|-----------|----------|
| Markdown | `.md` | Documentation, GitHub |
| HTML | `.html` | Interactive viewing |
| PDF | `.pdf` | Sharing, printing |
| LaTeX | `.tex` | Academic papers |
| Jupyter | `.ipynb` | Further analysis |

#### Report Contents

Customize what to include:

- [ ] Configuration summary
- [ ] Training progress charts
- [ ] Final metric table
- [ ] Metric progression charts
- [ ] Sample outputs (N samples)
- [ ] Failure analysis
- [ ] Comparison with baselines
- [ ] Statistical significance tests

### Automated Reporting

Schedule automatic reports:

```yaml
reporting:
  automatic: true
  triggers:
    - on_completion
    - daily_summary

  format: pdf
  recipients:
    - team@example.com

  include:
    - summary
    - metrics
    - best_samples: 10
    - worst_samples: 5
```

---

## 6. Experiment Management

### Experiment Lifecycle

```
Created → Queued → Running → Completed
                       ↓
                    Failed
                       ↓
                   Cancelled
```

### Experiment Actions

| Action | Description |
|--------|-------------|
| Clone | Create copy with same configuration |
| Archive | Move to archive (hidden from main list) |
| Delete | Permanently remove |
| Compare | Add to comparison view |
| Tag | Add/remove tags |
| Share | Generate shareable link |

### Experiment Organization

#### Tags

Categorize experiments:

```
#philosophy #production #v2 #best-so-far
```

#### Collections

Group related experiments:

- "Proposer Model Development"
- "Hyperparameter Search - LR"
- "Dataset Comparison"

#### Search and Filter

Find experiments by:

- Name (text search)
- Status
- Date range
- Metrics (e.g., entailment > 0.8)
- Tags
- Creator

---

## 7. Best Practices

### Before Training

1. **Validate Dataset**
   - Check for data quality issues
   - Ensure balanced splits
   - Review edge cases

2. **Start Small**
   - Run quick test first (small batch, few steps)
   - Verify training runs without errors
   - Check metric collection works

3. **Set Baselines**
   - Run baseline model first
   - Document baseline performance
   - Set improvement targets

### During Training

1. **Monitor Early**
   - Watch first 100 steps closely
   - Check loss is decreasing
   - Verify metrics are reasonable

2. **Save Checkpoints**
   - Checkpoint frequently enough
   - Keep best-performing checkpoints
   - Clean up unnecessary checkpoints

3. **Watch for Issues**
   - Loss not decreasing → check LR
   - Loss exploding → reduce LR
   - Metrics plateau → try different hyperparameters

### After Training

1. **Thorough Analysis**
   - Don't just look at final metrics
   - Analyze failures and edge cases
   - Check for overfitting

2. **Statistical Validation**
   - Run multiple seeds
   - Compute confidence intervals
   - Test statistical significance

3. **Documentation**
   - Document what worked/didn't
   - Save configuration for reproduction
   - Update experiment notes

---

## 8. Troubleshooting

### Common Issues

#### Training Won't Start

- **Check resources**: GPU available?
- **Check configuration**: Valid parameters?
- **Check dataset**: Accessible and valid format?

#### Training Fails Mid-Run

- **Out of memory**: Reduce batch size
- **CUDA error**: Update drivers, reduce model size
- **Data error**: Check for corrupted samples

#### Poor Results

- **High loss**: Learning rate too high/low
- **Low metrics**: Need more data or epochs
- **Overfitting**: Add regularization, more data

#### Slow Training

- **Low GPU utilization**: Increase batch size
- **Data loading bottleneck**: Enable prefetching
- **Network I/O**: Use local storage

### Getting Help

1. **Documentation**: Check docs first
2. **Logs**: Review detailed logs
3. **Community**: Ask in GitHub Issues
4. **Support**: Contact North-Shore-AI team
