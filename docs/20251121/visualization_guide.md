# CNS UI Visualization Guide

## Overview

This guide explains how to interpret the various metrics and visualizations in CNS UI. Understanding these metrics is essential for evaluating dialectical reasoning quality and guiding model improvements.

---

## 1. Chirality Scores

### What is Chirality?

Chirality in CNS measures the "handedness" or directional bias of dialectical reasoning. It captures asymmetries in how theses and antitheses are processed and synthesized.

### Score Range

- **Range**: -1.0 to +1.0
- **Ideal**: Near 0.0 (balanced processing)
- **Thresholds**:
  - `|score| < 0.1` - Excellent (highly balanced)
  - `|score| < 0.3` - Good (minor bias)
  - `|score| < 0.5` - Fair (noticeable bias)
  - `|score| >= 0.5` - Poor (significant bias)

### Interpretation

| Score | Meaning | Action |
|-------|---------|--------|
| -1.0 to -0.5 | Strong thesis bias | Review synthesizer; antitheses may be under-weighted |
| -0.5 to -0.1 | Moderate thesis lean | Monitor for patterns; may be domain-appropriate |
| -0.1 to +0.1 | Balanced | Optimal dialectical processing |
| +0.1 to +0.5 | Moderate antithesis lean | Check if antagonist is over-aggressive |
| +0.5 to +1.0 | Strong antithesis bias | Review antagonist calibration |

### Visual Representation

In CNS UI, chirality is displayed as:

1. **Gauge Chart** - Needle on -1 to +1 scale
2. **Color Coding**:
   - Green: |score| < 0.1
   - Yellow: 0.1 <= |score| < 0.3
   - Orange: 0.3 <= |score| < 0.5
   - Red: |score| >= 0.5
3. **Trend Line** - Historical chirality over time

### Common Causes of Imbalance

- **Negative (Thesis Bias)**:
  - Weak antagonist model
  - Insufficient antithesis training data
  - Overly conservative synthesis

- **Positive (Antithesis Bias)**:
  - Overly aggressive antagonist
  - Training data skewed toward contradictions
  - Synthesizer defaulting to antithesis

---

## 2. Fisher-Rao Metrics

### What is Fisher-Rao Distance?

Fisher-Rao distance measures the geometric distance between probability distributions in information geometry. In CNS, it quantifies how "far" dialectical positions are from each other.

### Components

#### 2.1 Thesis-Antithesis Distance
- **Range**: 0.0 to infinity (typically 0-10)
- **Meaning**: How different the thesis and antithesis are
- **Ideal**: 1.0-3.0 (meaningful opposition without being unrelated)

| Distance | Interpretation |
|----------|----------------|
| < 0.5 | Too similar - not true opposition |
| 0.5 - 1.0 | Mild opposition |
| 1.0 - 3.0 | Healthy dialectical tension |
| 3.0 - 5.0 | Strong opposition |
| > 5.0 | May be discussing different topics |

#### 2.2 Synthesis Distance from Inputs
- **Range**: 0.0 to infinity
- **Meaning**: How much the synthesis moves beyond inputs
- **Ideal**: 0.5-2.0 (novel but grounded)

| Distance | Interpretation |
|----------|----------------|
| < 0.3 | Synthesis too close to one input |
| 0.3 - 0.7 | Conservative synthesis |
| 0.7 - 2.0 | Creative synthesis |
| > 2.0 | May have drifted from inputs |

### Visual Representation

1. **2D Scatter Plot** - Positions in Fisher-Rao space
2. **Distance Matrix** - Pairwise distances as heatmap
3. **Trajectory Plot** - Synthesis movement from inputs
4. **Distribution Overlay** - Gaussian distributions at each position

### Use Cases

- **Quality Control**: Ensure syntheses are appropriately novel
- **Debugging**: Identify when positions are too similar/different
- **Comparison**: Compare reasoning patterns across experiments

---

## 3. Betti Numbers (Topology)

### What are Betti Numbers?

Betti numbers are topological invariants that describe the "shape" of data. In CNS, they characterize the structure of dialectical graphs.

### Betti Number Interpretations

#### B0 (Connected Components)
- **Meaning**: Number of disconnected groups
- **Ideal**: 1 (fully connected SNO)
- **Higher values**: Fragmented reasoning chains

| B0 | Interpretation |
|----|----------------|
| 1 | All propositions connected |
| 2-3 | Some isolated chains |
| > 3 | Fragmented structure |

#### B1 (Loops/Cycles)
- **Meaning**: Number of independent cycles
- **Ideal**: Domain-dependent
- **Higher values**: Circular reasoning or rich interconnection

| B1 | Interpretation |
|----|----------------|
| 0 | Tree-like structure (no cycles) |
| 1-3 | Some feedback loops |
| 4-7 | Complex interconnection |
| > 7 | May indicate circular reasoning |

#### B2 (Voids/Cavities)
- **Meaning**: Number of enclosed voids
- **Ideal**: Usually 0
- **Higher values**: Complex higher-order structure

### Visual Representation

1. **Bar Chart** - B0, B1, B2 values
2. **Persistence Diagram** - Topological features by scale
3. **Graph Visualization** - Colored by topological features
4. **Comparative Radar** - Compare topology across SNOs

### Interpreting Topology

**Healthy SNO Topology:**
- B0 = 1 (connected)
- B1 = 1-4 (some loops indicating synthesis connections)
- B2 = 0 (no higher voids)

**Red Flags:**
- B0 > 1: Disconnected arguments
- B1 > 10: Excessive circular reasoning
- B1 = 0: No synthesis connections (purely linear)

---

## 4. Evidence Grounding Scores

### What is Evidence Grounding?

Evidence grounding measures how well propositions are supported by cited evidence.

### Score Components

#### 4.1 Citation Coverage
- **Range**: 0.0 to 1.0
- **Meaning**: Fraction of propositions with citations
- **Ideal**: > 0.8 for factual claims

#### 4.2 Source Quality
- **Range**: 0.0 to 1.0
- **Meaning**: Reliability of cited sources
- **Factors**:
  - Source reputation
  - Publication date
  - Peer review status
  - Citation count

#### 4.3 Relevance Score
- **Range**: 0.0 to 1.0
- **Meaning**: How relevant citations are to propositions
- **Calculated via**: Semantic similarity

#### 4.4 Confidence Score
- **Range**: 0.0 to 1.0
- **Meaning**: Model's confidence in evidence-proposition link

### Composite Grounding Score

```
Grounding = 0.3 * Coverage + 0.25 * Quality + 0.25 * Relevance + 0.2 * Confidence
```

### Visual Representation

1. **Stacked Bar** - Component breakdown per proposition
2. **Heatmap** - Grounding across proposition tree
3. **Network Graph** - Evidence-proposition links
4. **Score Distribution** - Histogram of grounding scores

### Thresholds

| Score | Rating | Action |
|-------|--------|--------|
| 0.8 - 1.0 | Excellent | Production ready |
| 0.6 - 0.8 | Good | Minor improvements possible |
| 0.4 - 0.6 | Fair | Review weak citations |
| 0.0 - 0.4 | Poor | Significant grounding work needed |

---

## 5. Citation Validation Results

### Validation Status Types

#### 5.1 Valid
- Citation accessible
- Content matches quoted material
- Source is reliable

#### 5.2 Invalid - Broken Link
- URL returns 404 or error
- **Action**: Update or remove citation

#### 5.3 Invalid - Content Mismatch
- Source exists but content doesn't match
- **Action**: Verify quote accuracy

#### 5.4 Pending
- Not yet validated
- **Action**: Run validation

#### 5.5 Stale
- Validated > 30 days ago
- **Action**: Re-validate

### Visual Representation

1. **Status Badges** - Color-coded icons
   - Green: Valid
   - Red: Invalid
   - Yellow: Stale
   - Gray: Pending

2. **Pie Chart** - Distribution of statuses

3. **Timeline** - Validation history

4. **Alert List** - Citations needing attention

### Validation Metrics

| Metric | Target |
|--------|--------|
| Overall Validity | > 95% |
| Stale Citations | < 10% |
| Average Validation Age | < 14 days |

---

## 6. Entailment Verification

### What is Entailment?

Entailment verification checks if syntheses logically follow from their inputs (thesis + antithesis).

### Entailment Types

#### 6.1 Strict Entailment
- Synthesis logically necessary from inputs
- Most rigorous check

#### 6.2 Soft Entailment
- Synthesis reasonably follows from inputs
- Allows creative leaps

#### 6.3 Contradiction Check
- Synthesis doesn't contradict inputs
- Minimum requirement

### Score Interpretation

| Score | Type | Meaning |
|-------|------|---------|
| 1.0 | Pass | Entailment verified |
| 0.0 | Fail | Entailment not verified |
| 0.5 | Partial | Soft entailment only |

### Visual Representation

1. **Pass/Fail Badges** - Per synthesis
2. **Flow Diagram** - Colored by entailment status
3. **Failure Details** - Why entailment failed
4. **Trend Chart** - Pass rate over time

### Common Entailment Failures

- **Non-sequitur**: Synthesis unrelated to inputs
- **Over-generalization**: Synthesis too broad
- **Missing premise**: Requires unstated assumption
- **Contradiction**: Synthesis opposes an input

---

## 7. Quality Score Aggregation

### Overall Quality Score

The composite quality score combines multiple metrics:

```
Quality = w1*Chirality + w2*Grounding + w3*Topology + w4*Entailment + w5*Citation
```

Default weights:
- Chirality: 0.15
- Grounding: 0.25
- Topology: 0.15
- Entailment: 0.30
- Citation: 0.15

### Quality Grades

| Score | Grade | Description |
|-------|-------|-------------|
| 0.9 - 1.0 | A | Excellent quality |
| 0.8 - 0.9 | B | Good quality |
| 0.7 - 0.8 | C | Acceptable quality |
| 0.6 - 0.7 | D | Needs improvement |
| < 0.6 | F | Poor quality |

### Visual Dashboard

1. **Overall Score Gauge** - Large display
2. **Component Breakdown** - Radar chart
3. **Grade History** - Trend over time
4. **Comparison** - Vs baseline/average

---

## 8. Reading Visualizations

### Graph Interpretation Tips

1. **Node Size** = Confidence (larger = more confident)
2. **Node Color** = Type (T=Teal, A=Orange, S=Purple)
3. **Edge Thickness** = Relationship strength
4. **Clustering** = Related concepts

### Common Patterns

#### Healthy Patterns
- Balanced tree structure
- Strong synthesis connections
- Even confidence distribution

#### Warning Patterns
- Isolated nodes (disconnection)
- All edges to one node (over-reliance)
- Many red nodes (low confidence)

### Interactive Features

- **Hover**: Show details
- **Click**: Select for inspection
- **Double-click**: Expand subtree
- **Right-click**: Context menu
- **Scroll**: Zoom
- **Drag background**: Pan
- **Drag node**: Reposition

---

## 9. Exporting Visualizations

### Export Formats

| Format | Use Case |
|--------|----------|
| PNG | Presentations, documents |
| SVG | Scalable, editable graphics |
| PDF | Print-ready |
| JSON | Data interchange |
| CSV | Spreadsheet analysis |

### Export Options

- **Resolution**: Standard (72dpi), High (150dpi), Print (300dpi)
- **Include**: Legend, title, metadata
- **Background**: White, transparent, dark

---

## 10. Troubleshooting Visualizations

### Performance Issues

- **Slow rendering**: Reduce node count or use aggregation
- **Browser freeze**: Enable WebGL rendering
- **Memory errors**: Close other tabs, use pagination

### Display Issues

- **Overlapping nodes**: Switch to hierarchical layout
- **Missing edges**: Check filter settings
- **Wrong colors**: Verify color scheme settings

### Data Issues

- **Empty visualization**: Check data loaded successfully
- **Incorrect values**: Verify metric calculation settings
- **Stale data**: Refresh or check cache
