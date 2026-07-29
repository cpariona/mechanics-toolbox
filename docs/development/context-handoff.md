# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, create a branch, open a pull request, or merge changes unless explicitly requested.

## Validated implementation baseline

The latest validated implementation milestone is PR #34, merged into `main` as:

```text
bb61fb98308aa024779d4f4d4a28553e2904abe0
```

Recent merged milestones:

- PR #31 — remove the unused compression `signConvention` configuration and validation path while preserving automatic instrument-polarity normalization and physical negative compression signs;
- PR #32 — align tensile and compression drivers and reporting, separate individual and population tangent-modulus figure controls, add unit-aware population summaries, and present strain as `mm/mm` in maintained reports and figures;
- PR #33 — make tensile and compression Markdown table export robust to textual `missing` values;
- PR #34 — integrate fitting-window audit results into the maintained study reports, correct compression fitting-window direction, distinguish individual model selections from consensus-model population refits, and annotate variable population support.

The focused MATLAB suites and the complete repository test suite passed. The maintained real tensile and compression drivers were executed successfully. Their generated Markdown reports, CSV files, MAT files, and figures were reviewed.

## Validated current state

Primary maintained entrypoints:

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

Both drivers follow the same high-level organization:

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

Instrument force and displacement may be recorded with either polarity. Compression processing detects loading orientation and normalizes processed values to the physical negative-compression contract. Compression plots and reports may display positive magnitudes without changing the stored state.

## Fitting-window contract

`mechanics.fitting.fitAcrossWindows` builds nested windows from the state closest to zero deformation toward increasing deformation magnitude.

Therefore:

```text
tension:     0 -> positive strain
compression: 0 -> negative strain of increasing magnitude
```

This behavior operates on processed mechanical data and does not depend on acquisition ordering or raw instrument polarity.

The standard model-selection workflow:

- fits every configured model over every configured window;
- uses window-to-window parameter variability to assess stability;
- uses the full-window fit for final RMSE, R-squared, AIC, and BIC;
- applies convergence, stability, eligibility, parsimony, and ranking rules;
- stores every fitting result in `specimen.modelSelection.records`.

The configured `maximumRelativeParameterCV` remains a hard eligibility threshold. Reports now flag models close to that threshold and cases where a model excluded by stability had lower full-window RMSE than the selected model. Do not change this criterion without a dedicated analysis of the selection contract.

## Individual selection and consensus-model population

Two distinct results are maintained.

### Individual specimen selection

Each specimen retains the model selected by the standard fitting-window workflow. Root population exports use explicit names:

```text
individual_selected_model_parameter_values.csv
individual_selected_model_parameter_summary.csv
```

### Consensus-model population

The optional material-level workflow:

1. reads the individual standard-workflow selections;
2. determines the majority model using configured candidate order as the deterministic tie-break;
3. refits every retained specimen using that one consensus model;
4. summarizes the consensus-model parameters and equivalent initial shear modulus.

Maintained function:

```matlab
batch = mechanics.workflow.fitConsensusModelAcrossSpecimens( ...
    specimens, individualSelectedModels, candidateModelNames, ...
    fitConfig, batchConfig);
```

Outputs are stored under:

```text
consensus-model-population/
```

with explicit consensus-oriented filenames. Placeholder group summaries are not exported when every specimen belongs only to `Unassigned`.

`compareModelsAcrossSpecimens` remains a separate optional diagnostic/model-comparison workflow. It is not used to determine the standard consensus-model population in the maintained real drivers.

## Units and presentation contract

Processed strain remains dimensionless in the stored data contract:

```text
-
```

Maintained strain axes and reports present it as:

```text
mm/mm
```

This is presentation-only. Do not change stored values or the internal dimensionless-unit contract merely to alter labels.

Other units are resolved from processed specimen metadata, with maintained fallbacks including `N`, `mm`, `MPa`, and `mJ`.

## Reporting and figure export

Maintained reports:

```matlab
mechanics.io.exportTensileStudyReport
mechanics.io.exportCompressionStudyReport
mechanics.io.exportConstitutiveStudyReport
```

The tensile and compression study reports include, where available:

- study and exclusion summaries;
- per-specimen status and mechanical metrics with units;
- population status and central statistic;
- tangent-modulus population status and variable-support note;
- selected-model parameter summaries with units;
- constitutive fitting audit tables;
- warnings about sensitivity to the relative parameter-CV threshold;
- references to maintained figures;
- reproducibility metadata.

The fitting audit is part of the maintained primary report. It reads stored fitting results and does not refit models during report generation.

The audit figure uses:

- color for constitutive model;
- line style and marker for specimen;
- equivalent initial shear modulus versus fitting-window fraction.

Population tangent-modulus figures mark locations where the number of contributing specimens changes.

Maintained workflow figures are exported through `mechanics.plotting.exportFigureFiles` as:

```text
figure_name.png
figure_name.fig
```

Manual figures created directly in study drivers remain outside this persistence contract.

## Deferred findings and next priorities

1. Audit `maximumRelativeParameterCV` and the hard eligibility rule. The validated tensile data contain a specimen where Yeoh had substantially lower RMSE but was excluded because its parameter CV slightly exceeded `0.50`.
2. Audit selected-model and consensus-population statistics for `SampleCount < 2`. Decide whether dispersion and inference fields should become `NaN` or carry an explicit insufficient-count status.
3. Audit Issue #25 and define a limited contract for tensile-study comparison report export.
4. Review whether consensus should remain a simple majority vote or require a stronger material-level criterion. Do not change it without preserving the separation between individual selection and consensus refitting.
5. Possible model additions, including Ogden, remain deferred. Audit model registration, parameter naming, fitting support, tests, and documentation as one contract before adding a model.
6. Remove obsolete documentation, dead sections, or unused configuration only when a concrete inconsistency is demonstrated.

Prefer a small next phase. The highest-priority technical question is the sensitivity of model eligibility and selection to `maximumRelativeParameterCV`.

## Read first

1. `docs/development/context-handoff.md`
2. `README.md`
3. `docs/README.md`
4. `docs/development/repository-structure.md`
5. `docs/development/testing.md`
6. `docs/workflows/tensile-study.md`
7. `docs/workflows/compression-study.md`
8. documentation and implementation specific to the selected objective

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

Confirm that local `main` matches `origin/main` and that the working tree is clean. Do not continue work on a branch whose pull request has already been merged. Do not discard local or untracked files automatically.

Expected merged baseline before this documentation update:

```text
bb61fb98308aa024779d4f4d4a28553e2904abe0
```

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

For model-selection, population, or reporting changes, run focused suites first:

```matlab
focusedResults = runtests([
    "tests/test_model_selection.m"
    "tests/test_selected_parameter_population.m"
    "tests/test_batch_model_comparison.m"
    "tests/test_study_reporting.m"
    "tests/test_compression_study.m"
]);
assert(all([focusedResults.Passed]), ...
    "Focused model-selection, population, or reporting tests failed.")
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
- Keep instrument normalization, stored mechanics, fitting-window direction, and presentation conventions separate.
- Keep reusable code under `src/+mechanics`, real experiment drivers under `studies`, examples under `examples`, and tests under `tests`.
- Do not preserve obsolete APIs through wrappers or aliases.
- Remove superseded prompts and phase notes instead of maintaining competing sources of truth.
- Add files only when they represent a distinct maintained contract.
- Execute focused tests before the complete suite when behavior changes.
- Maintain relevant, nonredundant outputs by default; make optional only outputs that are genuinely diagnostic or costly.
- Do not extract shared driver helpers merely because scripts have similar syntax.
- Do not open or merge a pull request unless explicitly requested.

## Closing a work session

Record the selected scope, branch, latest commit SHA, tests executed, documentation changes, unresolved findings, and next concrete objective in this file only when the information is expected to remain useful beyond the current chat.
