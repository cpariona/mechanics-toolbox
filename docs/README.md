# Documentation

The documentation is organized by task. Persistent project state is maintained in one place: `development/context-handoff.md`.

## Workflows

- [`workflows/tensile-study.md`](workflows/tensile-study.md): end-to-end tensile analysis, experiment driver, population results, downstream constitutive workflows, reporting, and study-comparison export.
- [`workflows/tensile-application-range-characterization.md`](workflows/tensile-application-range-characterization.md): implemented add-on to a completed tensile study for range-limited shared hyperelastic characterization, parsimonious model selection, reference properties, fit-range sensitivity, unit-aware figures and export, and optional compression validation without refitting.
- [`workflows/compression-study.md`](workflows/compression-study.md): compression-cycle selection, study processing, shared uniaxial contracts, and reporting.
- [`workflows/constitutive-analysis.md`](workflows/constitutive-analysis.md): fitting, diagnostics, model comparison, parameter summaries, group inference, and reporting.
- [`workflows/joint-material-characterization.md`](workflows/joint-material-characterization.md): joint tension-compression characterization contract, model fitting and selection, driver ownership, outputs, and robustness auditing.

## Data

- [`data/import-and-processing.md`](data/import-and-processing.md): table import, workbook extraction, manifests, quality checks, and normalized specimen contracts.

## Reference

- [`reference/constitutive-models.md`](reference/constitutive-models.md): deformation measures, stress measures, model equations, and parameter definitions.
- [`reference/fit-diagnostics.md`](reference/fit-diagnostics.md): uncertainty, identifiability, window stability, residual diagnostics, and reliability.
- [`reference/peak-analysis.md`](reference/peak-analysis.md): peak segmentation, post-peak descriptors, and energy conventions.
- [`reference/geometry-uncertainty.md`](reference/geometry-uncertainty.md): propagation of initial-length and initial-area uncertainty.
- [`reference/population-and-group-analysis.md`](reference/population-and-group-analysis.md): replicate statistics and experimental group comparisons.
- [`reference/tensile-input-contracts.md`](reference/tensile-input-contracts.md): supported tensile-study inputs and normalization.

## Development

- [`development/context-handoff.md`](development/context-handoff.md): current validated state, next maintenance phase, architecture contracts, and continuation protocol.
- [`development/repository-structure.md`](development/repository-structure.md): maintained source layout, package ownership, and contribution boundaries.
- [`development/testing.md`](development/testing.md): focused tests and complete release validation.
- [`development/final-cleanup-audit.md`](development/final-cleanup-audit.md): historical snapshot of the cleanup completed after the tensile-study comparison migration. Its former “remaining work” section is not the current roadmap.

Development chronology belongs in Git history and merged pull requests. Superseded phase prompts and temporary handoff notes are not retained as parallel documentation.
