# Context handoff

Use this document when continuing repository work in a new chat.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, merge branches, or open a pull request unless explicitly requested.

## Validated current state

The tensile-study implementation is complete and maintained.

For one tensile study, use:

```matlab
study = mechanics.workflow.runTensileStudy(inputValue, config);
```

Supported inputs are a single workbook, file list, batch manifest, or pre-extracted dataset. They converge through `mechanics.workflow.normalizeTensileStudyInput` before common downstream analysis.

For comparison between completed tensile studies, use:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    studies, groupLabels, config);
```

The comparison workflow validates compatible measures and units, preserves input studies, namespaces duplicate specimen identifiers, and reuses the maintained population and group-analysis functions without reprocessing specimens.

PR #24 merged this comparison and removed the legacy row-oriented batch pipeline. Manifest input remains supported through `runTensileStudy`.

The complete MATLAB suite passed before merge. Post-merge validation also confirmed:

- identical study data produce zero metric and curve differences;
- a controlled 10% force increase produces approximately 10% increases in stress and tangent modulus;
- pre-extracted datasets must not reapply exclusions or index-based overrides already reflected in the dataset.

## Deferred work

Issue #25 records deferred export and reporting for tensile-study comparison. Do not implement it unless selected as an active objective.

A possible Ogden-model addition is also deferred. When a model is added, review the duplicated model-name declarations in `modelRegistry` and `listModels`.

## Current objective

Evaluate and design a shared uniaxial architecture for tension and compression.

The intended principle is:

- share import, unit normalization, force-displacement preparation, stress-strain measures, area evolution, tangent modulus, constitutive fitting, uncertainty, population analysis, and group comparison when their contracts are genuinely test-independent;
- retain test-specific handling for tensile peak/post-peak interpretation and for compression cycle selection, loading/unloading branches, contact, hysteresis, and compression reporting;
- avoid duplicating functions merely to preserve tension- or compression-specific names;
- do not force a generic orchestration layer until the common contract is demonstrated.

## Current sign-convention finding

`processUniaxialSpecimen` and `computeUniaxialMeasures` are already shared uniaxial components.

`runCompressionStudy` currently normalizes imported compression signals to positive compression magnitudes and later negates processed strain and stress for constitutive fitting. This works, but produces two representations of the same compression response.

The next phase must determine whether the maintained internal representation should use physical signs:

```text
tension:     displacement > 0, strain > 0, stress > 0, stretch > 1
compression: displacement < 0, strain < 0, stress < 0, 0 < stretch < 1
```

Positive compression magnitudes may remain a presentation choice, but presentation must not alter the stored mechanical state.

Do not change sign behavior before auditing existing tests, reports, cycle metrics, uncertainty propagation, fitting inputs, and public result fields.

## Initial phase boundary

Before implementation:

1. map the current tension and compression workflows;
2. identify functions that are already uniaxial;
3. identify generic behavior hidden behind tensile naming;
4. identify behavior that must remain test-specific;
5. trace every sign transformation from imported data to processed results, fitting, plotting, and export;
6. define the smallest safe first phase;
7. create a branch only after the scope is selected.

A likely first phase is to formalize and test the sign contract around `computeUniaxialMeasures` and compression preprocessing. Do not begin by introducing `runUniaxialStudy` or renaming public APIs.

A candidate branch, after scope approval, is:

```text
feature/uniaxial-tension-compression-unification
```

## Read first

1. `README.md`
2. `docs/README.md`
3. `docs/development/context-handoff.md`
4. `docs/development/repository-structure.md`
5. `docs/development/testing.md`
6. `docs/workflows/tensile-study.md`
7. `docs/workflows/compression-study.md`
8. `docs/data/import-and-processing.md`
9. `docs/reference/constitutive-models.md`
10. `docs/reference/population-and-group-analysis.md`
11. `docs/reference/tensile-input-contracts.md`

Then inspect only the implementation contracts required to evaluate the objective, beginning with:

```text
processUniaxialSpecimen
computeUniaxialMeasures
tensionConfig
compressionConfig
runTensileStudy
runCompressionStudy
analyzeExtractedDataset
analyzeSpecimenPopulation
compareTensileStudies
```

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

Confirm that local `main` matches `origin/main`. Do not discard local or untracked files automatically. Do not create a branch until the initial audit and scope selection are complete.

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

- Prefer one shared uniaxial implementation when the physical and data contracts are identical.
- Keep test-specific normalization and interpretation outside shared mechanics functions.
- Treat instrument sign convention, stored mechanical sign convention, and plotting convention as separate concerns.
- Preserve engineering/true measure selection and area-evolution behavior.
- Do not rename or generalize public APIs before proving a stable common contract.
- Do not create compatibility aliases for intentional API changes.
- Keep study drivers under `studies/`, reusable implementation under `src/+mechanics/`, and automated tests under `tests/`.
- Execute focused tests before the complete MATLAB suite whenever behavior changes.

## Closing a work session

Record the selected scope, branch, latest commit SHA, tests executed, sign-convention decisions, documentation changes, unresolved findings, and next concrete objective.