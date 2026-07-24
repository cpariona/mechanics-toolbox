# Context handoff

Use this document when continuing repository work in a new chat.

## Repository

```text
cpariona/mechanics-toolbox
```

Current maintenance branch:

```text
maintenance/api-doc-consistency
```

The previous implementation branch, `feature/mechanics-pipeline-refinement`, was merged into `main` through PR #16. Its merge commit is:

```text
4a55b6f476a112a3c8c1b4d5b70c21317121805e
```

Do not modify `main`, merge branches, or open a pull request unless explicitly requested.

## Current state

The maintained repository contains tensile and compression workflows, constitutive fitting, diagnostics, measurement-uncertainty propagation, population analysis, group comparison, plotting, exports, and automated tests.

The maintenance branch completed a direct breaking cleanup of terminology, examples, tests, and disconnected public functions. The user repeatedly reported that the complete MATLAB test suite passed after each functional cleanup block, including the final public-API cleanup.

The current phase is limited to:

1. repository-level diff and whitespace checks;
2. real-data validation of the tensile workflow;
3. pull-request preparation only when explicitly requested.

Prefer simple changes and uniform public names. Breaking cleanup is acceptable when explicitly chosen; repair affected callers and tests directly instead of retaining wrappers or compatibility aliases.

## Read first

Read only these files initially, in order:

1. `README.md`
2. `docs/README.md`
3. `docs/development/context-handoff.md`
4. `docs/development/repository-structure.md`
5. `docs/development/testing.md`
6. `docs/workflows/tensile-study.md`
7. `docs/reference/geometry-uncertainty.md`

Read additional implementation files only when needed for a concrete maintenance finding.

## Verify the repository before working

```bash
git fetch origin --prune
git switch maintenance/api-doc-consistency
git status -sb
git rev-parse HEAD
git rev-parse origin/maintenance/api-doc-consistency
git rev-parse origin/main
git log -5 --oneline --decorate
```

Report the local and remote SHAs, synchronization state, working-tree status, and recent relevant commits. Do not discard local changes automatically.

## Validation commands

Focused MATLAB test:

```matlab
startup
results = runtests("tests/test_name.m", "IncludeSubfolders", true);
disp(table(results))
assert(all([results.Passed]), "Focused tests failed.")
```

Complete suite:

```matlab
restoredefaultpath
clear classes
clear functions
clear
clc
close all

cd("D:\\Escritorio\\mechanics-toolbox")
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

Local experimental data and generated results are ignored under `data/` and `results/`. Do not delete them without confirming that anything needed has been preserved.

## Current conventions

- Maintained implementation belongs under `src/+mechanics/`.
- Runnable user examples belong under `examples/`.
- Example input templates belong under `examples/templates/`.
- Automated tests belong under `tests/`.
- Documentation belongs under `docs/`.
- Root MATLAB entrypoints are limited to `startup.m` and `run_all_tests.m`.
- `startup.m` adds only the repository root and `src`; examples and tests are not placed on the global path.
- Preserve raw experimental data separately from processed results.
- Prefer descriptive and uniform public names.
- Avoid `legacy`, `historical`, `old`, or similar terminology in maintained APIs and documentation.
- Do not retain wrappers or aliases solely for compatibility when a deliberate breaking cleanup has been selected.
- `processingHistory` means the processing trace applied to a specimen and should not be renamed casually.
- Peak and post-peak analysis is descriptive and must not claim automatic rupture classification.
- Keep a public plotting or validation utility only when it is consumed by a maintained workflow, report, runnable example, or documented public use case.

## Standardized names

Measurement Monte Carlo uses:

```text
measurementMonteCarlo
measurementMonteCarloFitConfig
measurementMonteCarloFitUncertainty
measurementMonteCarloFit
```

Peak analysis uses:

```text
peakAnalysis
peakAnalysisConfig
computePeakMetrics
addPeakMetrics
summarizePeakMetrics
exportPeakAnalysis
peakSummary
peakMetrics
```

All callers, tests, examples, exports, and documentation must use the canonical contracts above.

## Completed maintenance work

- Standardized measurement-uncertainty and peak-analysis terminology.
- Removed compatibility aliases, migration-only tests, and superseded APIs.
- Consolidated granular Ecoflex and fitting examples into maintained end-to-end workflows.
- Separated example templates from runnable scripts.
- Removed examples and tests from the global startup path.
- Reorganized mixed tests into subsystem-specific files.
- Removed duplicated comparison helpers, unused statistical helpers, disconnected plotting functions, and an isolated validation utility.
- Documented configuration hierarchy and public diagnostic contracts.
- Completed the stale-reference audit; only canonical public names remain in maintained documentation.

## Remaining review

- Run repository checks and inspect the complete branch diff.
- Validate the tensile workflow with representative real data when available.
- Open a pull request only after explicit user instruction.

Apply cleanup in small commits and rerun focused tests after each functional change. Run the complete suite before merge.

## Closing a work session

Before moving to another chat, record the working-tree state, latest commit SHA, tests executed, persistent-state changes, and the next concrete objective.
