# CNS UI Features

## Overview

This document provides complete specifications for all features in CNS UI, the Phoenix LiveView interface for CNS dialectical reasoning experiments.

---

## 1. Home Dashboard

### Purpose
Provide an at-a-glance overview of CNS system health, recent activity, and key metrics.

### Components

#### 1.1 System Health Panel
- **CNS Core Connection Status** - Connected/Disconnected indicator
- **Database Status** - PostgreSQL connection health
- **Active Experiments** - Count of running experiments
- **Queue Depth** - Pending synthesis tasks

#### 1.2 Key Metrics Summary
- **Total SNOs** - Count with trend indicator
- **Average Chirality Score** - Across all SNOs
- **Entailment Pass Rate** - Overall percentage
- **Citation Validity Rate** - Percentage of valid citations

#### 1.3 Recent Experiments Widget
- Last 5 experiments with status badges
- Quick actions (View, Clone, Delete)
- Progress bars for running experiments
- Completion time for finished experiments

#### 1.4 Quality Trends Chart
- Time-series visualization (7/30/90 day options)
- Metrics: Chirality, Entailment, Pass Rate
- Anomaly highlighting
- Export to CSV/PNG

#### 1.5 Quick Actions
- **New Experiment** - Start experiment wizard
- **Upload Dataset** - Quick dataset import
- **Browse SNOs** - Jump to SNO explorer
- **View Reports** - Recent generated reports

---

## 2. SNO Browser

### Purpose
Navigate, search, and explore Structured Narrative Objects.

### Components

#### 2.1 List View
- Sortable columns (Title, Created, Chirality, Citations)
- Bulk selection for batch operations
- Quick preview on hover
- Pagination with configurable page size

#### 2.2 Filter Panel
- **Date Range** - Created/modified date filters
- **Chirality Range** - Min/max slider
- **Experiment Source** - Filter by originating experiment
- **Citation Status** - Valid/Invalid/Pending
- **Tags** - Multi-select tag filter

#### 2.3 Search
- Full-text search across SNO content
- Proposition-level search
- Evidence text search
- Search history with suggestions

#### 2.4 View Modes
- **Grid View** - Card-based layout with previews
- **List View** - Compact table view
- **Tree View** - Hierarchical by experiment

---

## 3. SNO Detail Views

### Purpose
Deep inspection of individual SNO structure and content.

### Tabs

#### 3.1 Overview Tab
- **Title and Metadata** - ID, created date, source experiment
- **Summary Statistics** - Proposition count, depth, evidence count
- **Quality Scores** - Chirality, topology metrics, entailment
- **Tags and Labels** - Editable classification

#### 3.2 Structure Tab
- **Proposition Tree** - Interactive hierarchical view
  - Expand/collapse nodes
  - Color-coded by type (T/A/S)
  - Confidence indicators
  - Evidence links
- **Navigation Breadcrumb** - Current position in tree
- **Search Within** - Find propositions in current SNO

#### 3.3 Evidence Tab
- **Evidence Chain View** - All evidence with sources
- **Source Documents** - Linked source materials
- **Citation Validation Status** - Per-evidence validation
- **Confidence Distribution** - Histogram of evidence confidence

#### 3.4 Metrics Tab
- **Chirality Analysis** - Detailed score breakdown
- **Topology Metrics** - Betti numbers, connectivity
- **Consistency Scores** - Internal coherence metrics
- **Historical Comparison** - Compare with similar SNOs

#### 3.5 Graph Tab
- **Interactive Graph Visualization**
  - Force-directed layout
  - Hierarchical layout
  - Radial layout
- **Graph Controls**
  - Zoom/pan
  - Node filtering
  - Edge type visibility
  - Export to SVG/PNG

#### 3.6 Export Tab
- **Export Formats** - JSON, Markdown, LaTeX, PDF
- **Include Options** - Evidence, metrics, visualizations
- **Template Selection** - Report templates
- **Batch Export** - Export multiple SNOs

---

## 4. Dialectical Graph Visualizations

### Purpose
Visualize thesis-antithesis-synthesis flows and dialectical relationships.

### Features

#### 4.1 Graph Types
- **Flow Diagram** - Sequential T-A-S progression
- **Network Graph** - All proposition relationships
- **Hierarchy Tree** - Parent-child structure
- **Timeline View** - Temporal progression

#### 4.2 Visual Encodings
- **Node Color** - Type (Thesis=Teal, Antithesis=Orange, Synthesis=Purple)
- **Node Size** - Confidence score
- **Edge Width** - Relationship strength
- **Edge Style** - Relationship type (support, oppose, synthesize)

#### 4.3 Interactions
- **Click Node** - Show proposition details
- **Hover Node** - Quick preview tooltip
- **Double-click** - Expand/collapse subtree
- **Drag** - Reposition nodes
- **Lasso Select** - Multi-select for batch actions

#### 4.4 Animation
- **Synthesis Emergence** - Animated node appearance
- **Path Highlighting** - Trace dialectical chains
- **Diff Animation** - Show changes between versions

---

## 5. Proposer Output Displays

### Purpose
View and analyze raw proposer model outputs before antagonist review.

### Components

#### 5.1 Output List
- Chronological list of proposer outputs
- Status indicators (Pending, Reviewed, Accepted, Rejected)
- Confidence scores
- Model metadata (which model, parameters)

#### 5.2 Output Detail
- **Raw Text** - Original proposer output
- **Parsed Structure** - Extracted propositions
- **Confidence Breakdown** - Per-proposition confidence
- **Alternatives** - Other candidate outputs

#### 5.3 Comparison View
- Side-by-side output comparison
- Diff highlighting
- Metric comparison table

---

## 6. Antagonist Flagging Interface

### Purpose
Review antagonist-flagged propositions and adjudicate disputes.

### Components

#### 6.1 Flag Queue
- List of flagged propositions
- Severity indicators (Low/Medium/High/Critical)
- Flag reason categories
- Assignment status

#### 6.2 Review Panel
- **Original Proposition** - What was flagged
- **Flag Details** - Reason, evidence, antagonist notes
- **Context View** - Surrounding propositions
- **Historical Flags** - Previous flags on similar content

#### 6.3 Actions
- **Dismiss** - Clear flag as invalid
- **Modify** - Edit proposition to resolve
- **Escalate** - Send for human review
- **Accept** - Accept antagonist recommendation

#### 6.4 Analytics
- Flag frequency trends
- Common flag reasons
- Resolution time metrics
- Antagonist accuracy scores

---

## 7. Synthesizer Result Views

### Purpose
Display synthesis process results and quality analysis.

### Components

#### 7.1 Synthesis Summary
- **Input Summary** - Thesis and antithesis inputs
- **Output** - Generated synthesis proposition
- **Quality Score** - Overall synthesis quality
- **Processing Time** - Synthesis duration

#### 7.2 Quality Breakdown
- **Coherence Score** - Internal consistency
- **Coverage Score** - Input element incorporation
- **Novelty Score** - New insights generated
- **Grounding Score** - Evidence support

#### 7.3 Comparison Views
- Input vs Output comparison
- Multiple synthesis attempt comparison
- Before/after metric comparison

#### 7.4 Provenance Trail
- Step-by-step synthesis process
- Intermediate states
- Decision points
- Alternative paths considered

---

## 8. Training Configuration UI

### Purpose
Configure and manage CNS model training experiments.

### Wizard Steps

#### 8.1 Basic Configuration
- **Experiment Name** - Descriptive identifier
- **Description** - Purpose and goals
- **Tags** - Categorization labels
- **Priority** - Queue priority level

#### 8.2 Dataset Selection
- **Dataset Browser** - Available datasets
- **Upload New** - Import new dataset
- **Dataset Preview** - Sample data inspection
- **Split Configuration** - Train/val/test ratios

#### 8.3 Model Configuration
- **Model Type** - Proposer/Antagonist/Synthesizer
- **Base Model** - Foundation model selection
- **Hyperparameters**
  - Learning rate
  - Batch size
  - Epochs
  - Warmup steps
- **Advanced Options**
  - Gradient accumulation
  - Mixed precision
  - Checkpoint frequency

#### 8.4 Evaluation Configuration
- **Metrics Selection** - Which metrics to track
- **Evaluation Frequency** - How often to evaluate
- **Baseline Comparison** - Compare against baseline
- **Early Stopping** - Criteria and patience

#### 8.5 Resource Allocation
- **Compute Resources** - GPU selection
- **Memory Limits** - RAM allocation
- **Time Limits** - Maximum runtime
- **Concurrent Limit** - Parallel experiments

#### 8.6 Review and Launch
- **Configuration Summary** - All settings overview
- **Estimated Time** - Runtime estimate
- **Cost Estimate** - Resource cost
- **Launch Options** - Start now/schedule

### Training Monitor

#### 8.7 Progress Dashboard
- **Training Progress** - Epoch/step progress bar
- **Loss Curves** - Live updating charts
- **Metric Curves** - Evaluation metrics over time
- **Resource Usage** - GPU/CPU/Memory utilization

#### 8.8 Log Stream
- Real-time training logs
- Log level filtering
- Search in logs
- Export logs

#### 8.9 Checkpoint Management
- List of saved checkpoints
- Checkpoint metrics
- Load/resume from checkpoint
- Download checkpoint
- Delete old checkpoints

---

## 9. Quality Metrics Dashboards

### Purpose
Comprehensive quality monitoring and analysis for CNS outputs.

### Dashboards

#### 9.1 Entailment Dashboard
- **Overall Pass Rate** - Percentage of passing entailment checks
- **By Category** - Pass rates by proposition type
- **Trend Charts** - Pass rate over time
- **Failure Analysis** - Common failure patterns
- **Deep Dive** - Individual failure inspection

#### 9.2 Chirality Dashboard
- **Score Distribution** - Histogram of chirality scores
- **Trend Analysis** - Score evolution over time
- **Outlier Detection** - Anomalous scores
- **Correlation Analysis** - Chirality vs other metrics

#### 9.3 Consistency Dashboard
- **Internal Consistency** - Within-SNO consistency
- **Cross-SNO Consistency** - Across related SNOs
- **Temporal Consistency** - Stability over time
- **Contradiction Detection** - Flagged contradictions

#### 9.4 Citation Dashboard
- **Validation Status** - Overall citation health
- **Stale Citations** - Citations needing re-validation
- **Broken Links** - Dead citation links
- **Source Quality** - Source reliability scores

#### 9.5 Custom Dashboard Builder
- Drag-and-drop widget placement
- Custom metric combinations
- Saved dashboard configurations
- Share dashboard layouts

---

## 10. Reporting and Export

### Purpose
Generate and export reports for analysis and publication.

### Features

#### 10.1 Report Templates
- **Experiment Summary** - Single experiment overview
- **Comparison Report** - Multi-experiment comparison
- **Quality Report** - Detailed quality analysis
- **Publication Ready** - LaTeX-formatted for papers

#### 10.2 Export Formats
- **Markdown** - Documentation-friendly
- **HTML** - Interactive web reports
- **PDF** - Print-ready documents
- **LaTeX** - Academic publication format
- **Jupyter** - Notebook format for analysis

#### 10.3 Scheduling
- **Automated Reports** - Scheduled generation
- **Email Delivery** - Send to stakeholders
- **Webhook Integration** - Trigger external systems

---

## 11. Administration

### Features

#### 11.1 User Management
- User accounts and roles
- Permission configuration
- Activity logging
- Session management

#### 11.2 System Configuration
- CNS Core connection settings
- Database configuration
- Storage backends
- Feature flags

#### 11.3 Audit Log
- All user actions logged
- System events
- Security events
- Export audit trail

#### 11.4 Maintenance
- Database cleanup
- Cache management
- Log rotation
- Backup/restore

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+K` | Quick search |
| `Ctrl+N` | New experiment |
| `Ctrl+E` | Export current view |
| `?` | Show keyboard shortcuts |
| `G D` | Go to Dashboard |
| `G S` | Go to SNO Browser |
| `G X` | Go to Experiments |
| `G M` | Go to Metrics |

---

## Accessibility

CNS UI follows WCAG 2.1 AA guidelines:

- Full keyboard navigation
- Screen reader support
- High contrast mode
- Configurable text sizes
- Focus indicators
- ARIA labels throughout
