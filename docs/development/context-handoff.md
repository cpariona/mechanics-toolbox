# Context handoff

Use this document when continuing repository work in a new chat.

## Repository

```text
cpariona/mechanics-toolbox
```

The tensile study-driver work was completed on:

```text
feature/tensile-study-driver-phase1
```

After its pull request is merged, continue from an updated `main`. Do not continue development on the merged branch.

Do not modify `main`, merge branches, or open a pull request unless explicitly requested.

## Validated current state

The repository contains tensile and compression workflows, constitutive fitting, diagnostics, measurement-uncertainty propagation, population analysis, group comparison, plotting, exports, and automated tests.

The completed tensile study-driver scope includes:

- fitting context fields standardized as `deformationMeasure` and `stressMeasure`;
- retained defaults of `"engineering-strain"` and `"nominal"`;
- explicit rejection of the removed context field names instead of compatibility aliases;
- complete tangent-modulus calculation preserved in `tangentModulus`;
- plot-only leading-region suppression implemented through `tangentModulusForPlot`;
- automatic or manually configured plot start strain;
- executable real-experiment configurations placed under `studies/`;
- `studies/tension/run_tensile_experiment.m` centralizing the core tensile workflow and optional constitutive workflows;
- batch-manifest execution kept disabled pending result-contract unification.

The user reported the following validation on the final functional state:

- the complete MATLAB test suite passed;
- the complete real tensile experiment driver executed successfully;
- the grep for active assignments to the removed context fields returned no results.

## Next objective

The next technical objective is the deferred tensile-study extension described in:

```text
docs/development/tensile-study-follow-up.md
```

The intended order is:

1. implement the bounded tensile-study extensions;
2. validate them with focused tests, the complete suite, and representative real data;
3. perform a final cleanup and consistency audit after the extensions are stable.

Do not combine the final cleanup with the first implementation commits. Cleanup should follow functional validation so that unused contracts and duplicated paths can be identified from the completed design.

## Read first

Read these files in order:

1. `README.md`
2. `docs/README.md`
3. `docs/development/context-handoff.md`
4. `docs/development/repository-structure.md`
5. `docs/workflows/tensile-study.md`
6. `docs/development/tensile-study-follow-up.md`
7. `studies/README.md`
8. `studies/tension/run_tensile_experiment.m`

Use `docs/development/next-chat-prompt.md` as the prepared migration prompt.

Read additional implementation files only when required for a concrete design or maintenance finding.

## Verify the repository before working

After the phase-1 pull request has been merged:

```bash
git fetch origin --prune
git switch main
git pull --ff-only origin main
git status -sb
git rev-parse HEAD
git rev-parse origin/main
git log -5 --oneline --decorate
```

Confirm that local `main` matches `origin/main`. Do not discard local or untracked files automatically.

Before implementation, create a new branch from the verified `main`. Choose the branch name only after selecting the first bounded phase-2 objective.

## Validation baseline

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
git grep -n -E '\.(inputMeasure|outputStressMeasure)[[:space:]]*=' -- \
  src examples studies docs tests \
  ':!tests/test_fitting_context.m'

git diff --check
git status -sb
git status --ignored -s
git ls-files --others --exclude-standard
```

The assignment grep must remain empty. The removed names may appear only in guards and tests that verify their rejection.

## Current conventions

- Maintained implementation belongs under `src/+mechanics/`.
- Executable real-experiment configurations belong under `studies/`.
- Runnable API demonstrations belong under `examples/`.
- Example input templates belong under `examples/templates/`.
- Automated tests belong under `tests/`.
- Documentation belongs under `docs/`.
- Root MATLAB entrypoints are limited to `startup.m` and `run_all_tests.m`.
- `startup.m` adds only the repository root and `src`; studies, examples, and tests are not placed on the global path.
- Study drivers call maintained public APIs and may contain experiment-specific paths and settings, but not reusable implementation.
- Preserve raw experimental data and generated results under ignored paths.
- Do not retain wrappers or aliases solely for compatibility after an intentional breaking rename.
- Peak and post-peak analysis remains descriptive and must not claim automatic rupture classification.
- Prefer bounded, composable changes over expanding the core workflow indiscriminately.

## Deferred tensile-study work

The next development scope is:

1. population tangent-modulus interpolation and bootstrap summaries;
2. native selected-parameter plots grouped by model and parameter;
3. derived initial shear-modulus plots across specimens;
4. a study-level consensus model using eligibility, median BIC, stability, and parsimony;
5. unification of workbook, file-list, pre-extracted dataset, and batch-manifest inputs under one tensile-study result contract.

The input-contract migration is the most architectural item. Audit it before implementation and keep it separate if it would make the first phase-2 branch too broad.

## Cleanup after phase 2

After the functional additions are merged and validated, perform a separate cleanup audit covering:

- duplicated or superseded workflows;
- public functions with no maintained consumers;
- configuration fields that no longer affect execution;
- plotting and export overlap;
- study-driver duplication;
- stale documentation, examples, and tests;
- naming and result-contract consistency.

Do not remove APIs solely from consumer counts. Inspect dynamic use, documented public contracts, report entrypoints, and test intent before deletion.

## Closing a work session

Record the branch state, latest commit SHA, tests executed, persistent-state changes, unresolved findings, and the next concrete objective.