# Context handoff

Use this document when continuing repository work in a new chat.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, merge branches, or open a pull request unless explicitly requested.

## Validated current state

The repository contains maintained tensile and compression workflows, constitutive fitting, diagnostics, uncertainty propagation, population analysis, group comparison, study-level model consensus, plotting, exports, and automated tests.

The tensile workflow supports:

```text
single workbook
file list
batch manifest
pre-extracted dataset
```

All four inputs converge through `mechanics.workflow.normalizeTensileStudyInput` before the common downstream analysis. `mechanics.workflow.runTensileStudy` is the preferred end-to-end tensile entrypoint.

Completed and validated tensile functionality includes:

- standardized fitting context fields `deformationMeasure` and `stressMeasure`;
- complete and plot-oriented tangent-modulus curves;
- population stress-strain and tangent-modulus analysis;
- specimen-level model comparison;
- selected-parameter and initial-shear-modulus summaries;
- study-level consensus model selection;
- experimental group comparison and selected-parameter group inference;
- integrated tables, figures, MAT outputs, and Markdown reports;
- workbook, file-list, manifest, and dataset input equivalence.

Validation completed through focused tests, the complete MATLAB suite, the maintained real tensile experiment, generated-output inspection, and real workbook versus normalized-dataset equivalence.

## Current maintenance objective

The functional phase is complete. Remaining work is bounded repository cleanup and broader real-data validation.

Read:

```text
docs/development/tensile-study-follow-up.md
docs/development/final-cleanup-audit.md
```

before proposing removals or consolidation.

## Maintained workflow boundaries

- `runTensileStudy` is the preferred end-to-end tensile workflow.
- `processBatchManifest` is a legacy row-oriented processor retained for skipped-row records, per-row failure capture, optional specimen export, and mixed tension/compression support.
- `processBatchManifest` does not perform population analysis or experimental group comparison.
- Experimental group labels are assigned after processing and consumed by group-analysis workflows.
- Study drivers belong under `studies/` and must call maintained public APIs rather than duplicate implementation.
- Generated data and experimental workbooks remain under ignored paths.

## Read first

Read these files in order:

1. `README.md`
2. `docs/README.md`
3. `docs/development/context-handoff.md`
4. `docs/development/repository-structure.md`
5. `docs/development/final-cleanup-audit.md`
6. `docs/workflows/tensile-study.md`
7. `docs/reference/tensile-input-contracts.md`
8. `docs/reference/population-and-group-analysis.md`
9. `studies/README.md`
10. `studies/tension/run_tensile_experiment.m`

Read additional implementation files only when required for a concrete maintenance finding.

## Verify the repository before working

```bash
git fetch origin --prune
git switch main
git pull --ff-only origin main
git status -sb
git rev-parse HEAD
git rev-parse origin/main
git log -5 --oneline --decorate
```

Confirm that local `main` matches `origin/main`. Do not discard local or untracked files automatically. Create a new branch before modifying files.

## Validation baseline

```matlab
restoredefaultpath
clear classes
clear functions
clear
clc
close all

cd("D:\Escritorio\mechanics-toolbox")
startup
results = run_all_tests();
assert(all([results.Passed]), "Repository tests failed.")
```

Repository checks:

```bash
git diff --check
git status -sb
git status --ignored -s
git ls-files --others --exclude-standard
```

## Cleanup rules

- Do not remove APIs based only on consumer counts.
- Inspect documented contracts, dynamic use, maintained studies, examples, and test intent.
- Do not create compatibility aliases for intentional renames.
- Prefer internal consolidation over new public wrappers.
- Preserve descriptive peak and post-peak interpretation; do not claim automatic rupture classification.
- Keep functional changes separate from broad cleanup when validation risk increases.

## Closing a work session

Record the branch, latest commit SHA, tests executed, documentation changes, unresolved findings, and next concrete objective.
