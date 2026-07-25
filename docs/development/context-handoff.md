# Context handoff

Use this document when continuing repository work in a new chat.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, merge branches, or open a pull request unless explicitly requested.

## Validated current state

The repository contains maintained tensile and compression workflows, constitutive fitting, diagnostics, uncertainty propagation, population analysis, group comparison, study-level model consensus, plotting, exports, and automated tests.

For one tensile study, use:

```matlab
study = mechanics.workflow.runTensileStudy(inputValue, config);
```

Supported inputs are:

```text
single workbook
file list
batch manifest
pre-extracted dataset
```

All inputs converge through `mechanics.workflow.normalizeTensileStudyInput` before common downstream analysis.

For comparison between completed studies, use:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    studies, groupLabels, config);
```

The comparison workflow validates compatible stress and strain measures, validates processed units, namespaces specimen identifiers, preserves original identifiers, and reuses the maintained group-analysis workflow without reprocessing specimens.

## Removed legacy pipeline

The following row-oriented batch-processing files were removed after `compareTensileStudies` passed focused tests:

```text
processBatchManifest.m
summarizeBatchResults.m
batchProcessingConfig.m
exportBatchSummary.m
test_batch_processing.m
```

Manifest input remains supported by `runTensileStudy`. Keep:

```text
validateBatchManifest.m
readBatchManifest.m
specimen_manifest_template.csv
```

Manifest validation coverage now belongs to `tests/test_tensile_study_input_contracts.m`.

## Current objective

The current branch is:

```text
feature/tensile-study-comparison
```

The initial comparison contract covers population stress-strain curves and scalar mechanical metrics. Remaining optional extensions are selected constitutive parameters, initial shear modulus, consensus-model comparison, dedicated export/reporting, and validation with two real material workbooks.

Read:

```text
docs/development/final-cleanup-audit.md
docs/reference/population-and-group-analysis.md
docs/reference/tensile-input-contracts.md
```

before extending the comparison contract.

## Read first

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

Read additional implementation files only when required for a concrete finding.

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

## Maintenance rules

- Prefer composition of maintained results over reprocessing or refitting.
- Preserve input study results unchanged during comparison.
- Do not create compatibility aliases for removed APIs.
- Keep study drivers under `studies/`, reusable implementation under `src/+mechanics/`, and automated tests under `tests/`.
- Preserve descriptive peak and post-peak interpretation; do not claim automatic rupture classification.

## Closing a work session

Record the branch, latest commit SHA, tests executed, documentation changes, unresolved findings, and next concrete objective.
