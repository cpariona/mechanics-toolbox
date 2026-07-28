# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, create a branch, open a pull request, or merge changes unless explicitly requested.

## Validated current state

The maintained tensile and compression workflows are complete and share the common uniaxial mechanics implementation where their physical contracts are identical.

Primary entrypoints:

```matlab
study = mechanics.workflow.runTensileStudy(inputValue, config);
study = mechanics.workflow.runCompressionStudy(inputValue, config);
```

Completed studies can be compared without re-importing or reprocessing specimens:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    studies, groupLabels, config);

comparison = mechanics.workflow.compareCompressionStudies( ...
    studies, groupLabels, config);
```

Maintained real-experiment drivers:

```text
studies/tension/run_tensile_experiment.m
studies/compression/run_compression_experiment.m
```

Reusable implementation belongs under `src/+mechanics`. Drivers retain experiment-specific paths, exclusions, assumptions, settings, optional analyses, and manual inspection figures.

## Shared uniaxial contract

Tension and compression share maintained implementations for:

- import normalization and processed specimen contracts;
- engineering and true strain/stress measures;
- area evolution;
- tangent-modulus estimation;
- constitutive fitting and model selection;
- measurement Monte Carlo and geometry uncertainty;
- population aggregation and group comparison;
- selected-parameter and constitutive downstream analyses;
- unit-aware plotting labels;
- maintained figure export.

Test-specific behavior remains separate:

- tension: loading segmentation, peak and post-peak descriptors;
- compression: cycle selection, loading/unloading branches, contact-oriented preprocessing, hysteresis and cycle diagnostics.

The stored mechanical sign convention is physical:

```text
tension:     displacement > 0, strain > 0, stress > 0, stretch > 1
compression: displacement < 0, strain < 0, stress < 0, 0 < stretch < 1
```

Compression plots and reports may display positive magnitudes without changing the stored state.

## Reporting and figure export

Maintained study reports are available through:

```matlab
mechanics.io.exportTensileStudyReport
mechanics.io.exportCompressionStudyReport
mechanics.io.exportConstitutiveStudyReport
```

Maintained workflow figures are exported through `mechanics.plotting.exportFigureFiles` as:

```text
figure_name.png   % or configured image format
figure_name.fig   % editable MATLAB figure
```

Manual figures created directly in study drivers are outside this persistence contract.

## Deferred work

Issue #25 remains open for dedicated export and reporting of tensile-study comparison results. It is not the report for one tensile study.

Possible model additions, including Ogden, remain deferred. Before adding a model, audit model registration, parameter naming, fitting support, tests, and documentation as one contract.

## Current maintenance priorities

Prefer small phases that improve structure, naming, organization, and simplicity before adding new functionality.

Current priorities are:

1. remove obsolete documentation and dead driver sections;
2. audit duplicated driver preparation logic before extracting shared helpers;
3. audit configuration functions against real consumers;
4. review public naming only where simplification outweighs API churn;
5. avoid compatibility wrappers and unnecessary files.

## Read first

1. `README.md`
2. `docs/README.md`
3. `docs/development/context-handoff.md`
4. `docs/development/repository-structure.md`
5. `docs/development/testing.md`
6. `docs/workflows/tensile-study.md`
7. `docs/workflows/compression-study.md`
8. documentation specific to the selected objective

Inspect only implementation contracts required by the chosen scope.

## Repository verification

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

- Share implementation only when physical and data contracts are genuinely common.
- Keep instrument normalization, stored mechanics, and presentation conventions separate.
- Keep reusable code under `src/+mechanics`, real experiment drivers under `studies`, examples under `examples`, and tests under `tests`.
- Do not preserve obsolete APIs through wrappers or aliases.
- Remove superseded prompts and phase notes instead of maintaining competing sources of truth.
- Add files only when they represent a distinct maintained contract.
- Execute focused tests before the complete suite when behavior changes.

## Closing a work session

Record the selected scope, branch, latest commit SHA, tests executed, documentation changes, unresolved findings, and next concrete objective in this file only when the information is expected to remain useful beyond the current chat.