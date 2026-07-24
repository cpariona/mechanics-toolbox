# Context handoff

Use this document when continuing repository work in a new chat.

## Repository

```text
cpariona/mechanics-toolbox
```

Current branch:

```text
feature/tensile-study-driver-phase1
```

PR #17 merged the API, example, test, and repository-structure cleanup into `main` before this branch was created.

Do not modify `main`, merge branches, or open a pull request unless explicitly requested.

## Current state

The repository contains tensile and compression workflows, constitutive fitting, diagnostics, measurement-uncertainty propagation, population analysis, group comparison, plotting, exports, and automated tests.

The current branch establishes an executable tensile experiment driver and a small usability cleanup:

- fitting context fields are `deformationMeasure` and `stressMeasure`;
- the retained defaults are `"engineering-strain"` and `"nominal"`;
- removed context field names are rejected explicitly rather than accepted as aliases;
- tangent-modulus calculation retains the complete derivative while `tangentModulusForPlot` omits only an initial plot interval;
- plot trimming is automatic by default and may be overridden with a minimum strain;
- real experiment configurations belong under `studies/`;
- `studies/tension/run_tensile_experiment.m` centralizes the core workflow and optional constitutive workflows;
- batch-manifest execution remains disabled pending result-contract unification.

## Read first

Read only these files initially, in order:

1. `README.md`
2. `docs/README.md`
3. `docs/development/context-handoff.md`
4. `docs/development/repository-structure.md`
5. `docs/workflows/tensile-study.md`
6. `docs/development/tensile-study-follow-up.md`
7. `studies/tension/run_tensile_experiment.m`

Read additional implementation files only when required for a concrete finding.

## Verify the repository before working

```bash
git fetch origin --prune
git switch feature/tensile-study-driver-phase1
git status -sb
git rev-parse HEAD
git rev-parse origin/feature/tensile-study-driver-phase1
git rev-parse origin/main
git log -5 --oneline --decorate
```

Do not discard local changes automatically.

## Validation commands

Focused tests:

```matlab
restoredefaultpath
clear classes
clear functions
clear
clc
close all

cd("D:\\Escritorio\\mechanics-toolbox")
startup

results = runtests([ ...
    "tests/test_constitutive_fitting.m", ...
    "tests/test_fitting_context.m", ...
    "tests/test_tangent_modulus_plotting.m", ...
    "tests/test_measurement_monte_carlo.m", ...
    "tests/test_tensile_study.m", ...
    "tests/test_study_reporting.m", ...
    "tests/test_compression_study.m"], ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), "Focused tests failed.")
```

Complete suite:

```matlab
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

The assignment grep must be empty. The removed names remain intentionally inside model guards and `test_fitting_context.m`, where their rejection is tested.

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

## Deferred tensile-study work

The viability audit and next bounded scope are recorded in:

```text
docs/development/tensile-study-follow-up.md
```

The deferred work is:

1. population tangent-modulus interpolation and bootstrap summaries;
2. native selected-parameter plots grouped by model and parameter;
3. derived initial shear-modulus plots across specimens;
4. a specimen-level consensus model using eligibility, median BIC, stability, and parsimony;
5. unification of workbook and batch-manifest inputs under one tensile-study result contract.

Do not begin these items implicitly. Start them as a separate objective after the current branch is validated and closed.

## Closing a work session

Record the branch state, latest commit SHA, tests executed, persistent-state changes, unresolved grep results, and the next concrete objective.
