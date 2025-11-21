# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-11-21

### Added

- Initial release of CNS UI
- Phoenix LiveView-based web interface
- Database schema for SNOs, experiments, training runs, citations, challenges, and metrics
- Dashboard with system health indicators and key CNS metrics
- SNO browser with filterable list/grid views
- SNO detail view with tabs (overview, structure, evidence, metrics, graph)
- Experiment management interface
- Training configuration wizard (6-step)
- Quality metrics dashboard
- Proposer output display
- Antagonist challenge management
- Synthesizer results display
- Graph visualization placeholder (D3.js integration coming soon)
- Visualization components:
  - ChiralityGauge
  - EntailmentMeter
  - TopologyGraph
  - EvidenceTree
- Comprehensive test suite for contexts and LiveViews
- Configuration for development, test, and production environments
- Apache 2.0 license
