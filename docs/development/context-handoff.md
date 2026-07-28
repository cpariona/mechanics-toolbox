# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, create a branch, open a pull request, or merge changes unless explicitly requested.

## Validated implementation baseline

The latest validated implementation milestone is PR #32, merged into `main` as:

```text
81992c8718940eb994bb3dba9ce3652307cf32ee
```

Recent merged milestones:

- PR #31 — remove the unused compression `signConvention` configuration and validation path while preserving automatic instrument-polarity normalization and physical negative compression signs;
- PR #32 — align tensile and compression drivers and reporting, separate individual and population tangent-modulus figure controls, add unit-aware population summaries, and present strain as `mm/mm` in maintained reports and figures.

The complete MATLAB test suite passed after these changes. The maintained real tensile and compression drivers were also executed successfully, and their generated reports and figures were reviewed.

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

Both drivers now follow the same high-level organization:

1. experiment-specific configuration and assumptions;
2. maintained study workflow execution;
3. maintained report generation;
4. results and distinct interactive diagnostics;
5. optional downstream workflows.

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

Instrument force and displacement may be recorded with either polarity. Compression processing detects loading orientation and normalizes the processed force, displacement, strain, and stress to the physical negative-compression contract. Negative import scale factors remain available for explicit unit conversion or instrument-polarity correction.

Compression plots and reports may display positive magnitudes without changing the stored state.

## Units and presentation contract

Processed strain remains dimensionless in the stored data contract. The normalized internal unit is:

```text
-
```

Maintained strain axes and reports present this quantity as:

```text
mm/mm
```

This conversion is presentation-only. Do not change stored strain values or the internal dimensionless-unit contract merely to alter report or plotting labels.

Other units are resolved from processed specimen metadata, with maintained fallbacks including `N`, `mm`, `MPa`, and `mJ`.

## Reporting and figure export

Maintained study reports are available through:

```matlab
mechanics.io.exportTensileStudyReport
mechanics.io.exportCompressionStudyReport
mechanics.io.exportConstitutiveStudyReport
```

The tensile and compression study reports now include, where available:

- study and exclusion summaries;
- per-specimen status and mechanical metrics with units;
- population status and central statistic;
- tangent-modulus population status;
- selected-model parameter summaries with units;
- references to maintained exported figures;
- reproducibility metadata.

Tensile individual and population tangent-modulus figures are controlled independently through:

```matlab
config.includeTangentModulus
config.includePopulationTangentModulus
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

The selected-model population summary currently reports degenerate dispersion and confidence values when a model has only one retained specimen. Before changing this behavior, audit the shared selected-parameter summary contract and decide whether insufficient sample counts should produce `NaN` inference fields or an explicit status.

## Current maintenance priorities

Prefer small phases that improve structure, naming, organization, and simplicity before adding new functionality.

Current priorities are:

1. audit Issue #25 and define a limited contract for tensile-study comparison report export;
2. audit selected-model population statistics for `SampleCount < 2` without changing fitting or model-selection behavior;
3. remove obsolete documentation and dead driver sections only when a concrete inconsistency is identified;
4. audit configuration fields against real consumers and remove only fields proven to have no behavioral effect;
5. review public naming only where simplification clearly outweighs API churn;
6. avoid compatibility wrappers, aliases, bridge helpers, and unnecessary files.

Do not extract shared driver helpers merely because two scripts have similar syntax. Share implementation only when the physical responsibility, data contract, lifecycle, and error behavior are genuinely common.

## Read first

1. `docs/development/context-handoff.md`
2. `README.md`
3. `docs/README.md`
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

Confirm that local `main` matches `origin/main`. Do not continue work on a branch whose pull request has already been merged. Do not discard local or untracked files automatically.

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

When reporting or plotting behavior changes, run the focused suites first:

```matlab
focusedResults = runtests( ...
    ["tests/test_plotting_units.m", ...
     "tests/test_study_reporting.m", ...
     "tests/test_compression_study.m"], ...
    "IncludeSubfolders", true);
assert(all([focusedResults.Passed]), ...
    "Focused plotting or reporting tests failed.")
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
- Maintain relevant, nonredundant outputs by default; make optional only outputs that are genuinely diagnostic or costly.

## Closing a work session

Record the selected scope, branch, latest commit SHA, tests executed, documentation changes, unresolved findings, and next concrete objective in this file only when the information is expected to remain useful beyond the current chat.
