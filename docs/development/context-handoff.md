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

The complete MATLAB test suite passed before PR #16 was merged. Maintenance changes must be validated again before merge.

The current phase is intentionally limited to:

1. repository organization and cleanup;
2. terminology and public-API consistency;
3. documentation review;
4. real-data validation of the tensile workflow.

Prefer simple changes. Preserve compatibility and avoid new abstractions unless they solve a demonstrated problem.

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

Run:

```bash
git fetch origin --prune
git switch maintenance/api-doc-consistency
git status -sb
git rev-parse HEAD
git rev-parse origin/maintenance/api-doc-consistency
git rev-parse origin/main
git log -5 --oneline --decorate
```

Report:

- local branch and SHA;
- remote branch SHA;
- whether the branch is ahead, behind, or synchronized;
- working-tree status;
- recent relevant commits.

Do not discard local changes automatically.

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
clear
clc
close all
results = run_all_tests();
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
- Automated tests belong under `tests/`.
- Documentation belongs under `docs/`.
- Root MATLAB entrypoints are limited to `startup.m` and `run_all_tests.m`.
- Preserve raw experimental data separately from processed results.
- Prefer descriptive and uniform public names.
- Avoid `legacy`, `historical`, `old`, or similar terminology in maintained APIs and documentation.
- Preserve established public contracts through aliases when a clearer canonical name is introduced.
- `processingHistory` means the processing trace applied to a specimen and should not be renamed casually.
- Peak and post-peak analysis is descriptive and must not claim automatic fracture classification.

## Current maintenance findings

The following naming inconsistency is confirmed:

- tensile configuration uses `measurementMonteCarlo`;
- compression configuration and public helper names use `geometryMonteCarlo` even though the calculation can also perturb force and displacement.

The preferred canonical terminology is `measurementMonteCarlo`. Existing geometry-named entrypoints should remain available as compatibility aliases until a deliberate breaking release.

## Pending review

Continue the review without broad refactoring:

- obsolete or duplicated examples;
- unused public functions or configuration options;
- stale terminology in source, tests, exports, and documentation;
- consistency between documented and accepted option names;
- test organization without removing coverage;
- real-data execution of the tensile workflow.

Apply cleanup in small commits and rerun focused tests after each functional change. Run the complete suite before merge.

## Closing a work session

Before moving to another chat:

1. record the working-tree state;
2. record the latest commit SHA;
3. record which tests passed;
4. update this document only when persistent state or the next phase changes;
5. provide a short prompt for the next chat.
