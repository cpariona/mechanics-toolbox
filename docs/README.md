# Documentation

The documentation is organized by task.

## Workflows

- [`workflows/tensile-study.md`](workflows/tensile-study.md): end-to-end tensile analysis, executable study driver, and reporting.
- [`workflows/compression-study.md`](workflows/compression-study.md): last-cycle compression selection and specimen processing.
- [`workflows/constitutive-analysis.md`](workflows/constitutive-analysis.md): fitting, diagnostics, model comparison, parameter summaries, group inference, and reporting.

## Data

- [`data/import-and-processing.md`](data/import-and-processing.md): table import, workbook extraction, batch manifests, quality checks, and normalized specimen contracts.

## Reference

- [`reference/constitutive-models.md`](reference/constitutive-models.md): deformation measures, stress measures, model equations, and parameter definitions.
- [`reference/fit-diagnostics.md`](reference/fit-diagnostics.md): uncertainty, identifiability, window stability, residual diagnostics, and reliability.
- [`reference/peak-analysis.md`](reference/peak-analysis.md): peak segmentation, post-peak descriptors, and energy conventions.
- [`reference/geometry-uncertainty.md`](reference/geometry-uncertainty.md): propagation of initial-length and initial-area uncertainty to stress and strain.
- [`reference/population-and-group-analysis.md`](reference/population-and-group-analysis.md): replicate statistics and experimental group comparisons.
- [`reference/tensile-input-contracts.md`](reference/tensile-input-contracts.md): workbook, file-list, manifest, and pre-extracted dataset inputs for the tensile workflow.

## Development

- [`development/context-handoff.md`](development/context-handoff.md): persistent state and protocol for continuing repository work.
- [`development/next-chat-prompt.md`](development/next-chat-prompt.md): ready-to-copy prompt for the next tensile-study development chat.
- [`development/repository-structure.md`](development/repository-structure.md): maintained source layout and contribution boundaries.
- [`development/testing.md`](development/testing.md): focused tests and complete release validation.
- [`development/tensile-study-follow-up.md`](development/tensile-study-follow-up.md): completed tensile-study scope and remaining maintenance boundaries.
- [`development/final-cleanup-audit.md`](development/final-cleanup-audit.md): final cleanup decisions, retained legacy behavior, and deferred consolidation.

Development chronology is retained in Git history and merged pull requests.
