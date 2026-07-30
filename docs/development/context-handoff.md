# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Validated implementation baseline

The latest merged baseline before the current pull request is:

```text
97e477568b4c9c09eafe63ced04cc09ecbef615a
```

This includes PR #34 and the validated tensile/compression fitting audit, consensus-model population workflow, unit-aware reporting, and maintained study exports.

The current branch is:

```text
audit/model-selection-evidence
```

It contains the completed model-selection diagnostic revision described below. The focused MATLAB suites and the complete repository test suite passed. The maintained real tensile and compression drivers were executed successfully, and regenerated MAT, CSV, report, and figure outputs were reviewed.

## Maintained entrypoints

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

Both drivers retain experiment-specific paths, exclusions, assumptions, settings, optional analyses, and distinct inspection figures. Reusable implementation belongs under `src/+mechanics`.

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

Stored mechanical signs remain physical:

```text
tension:     displacement > 0, strain > 0, stress > 0, stretch > 1
compression: displacement < 0, strain < 0, stress < 0, 0 < stretch < 1
```

Instrument polarity may vary. Compression processing normalizes processed values to the physical negative-compression contract. Presentation may use positive magnitudes without changing stored state.

## Fitting-window contract

`mechanics.fitting.fitAcrossWindows` builds nested windows from the state closest to zero deformation toward increasing deformation magnitude:

```text
tension:     0 -> positive strain
compression: 0 -> negative strain of increasing magnitude
```

The standard model-selection workflow:

- fits every configured model over every configured window;
- stores every fitting result in `specimen.modelSelection.records`;
- uses the full-window fit for final RMSE, R-squared, AIC, and BIC;
- requires all configured windows to succeed;
- applies configured convergence requirements;
- requires finite full-window parameters and metrics;
- ranks eligible models using full-window fit quality, practical RMSE equivalence, parsimony, the configured information criterion, and shared-domain response sensitivity.

### Parameter sensitivity

Window-to-window parameter variability remains available through:

```text
ParameterMeans
ParameterStd
ParameterCV
MaximumRelativeParameterCV
DominantCVParameter
HasParameterSignChange
```

These are diagnostics. `MaximumRelativeParameterCV` is no longer a hard eligibility threshold and no threshold field remains in `modelSelectionConfig` or the maintained drivers.

The dedicated audit of the real tensile data showed that the former rule could exclude Yeoh-3 because `C30` varied across windows even when:

- all multistarts converged to the same full-window solution;
- the shared-domain predicted response was stable;
- full-window RMSE and BIC strongly favored Yeoh-3;
- the `C30` contribution was material at high deformation.

### Shared-domain response sensitivity

`summarizeWindowStability` now compares each reduced-window prediction with the full-window prediction only over their shared deformation domain. It reports:

```text
MaximumSharedDomainNormalizedRMSE
MaximumSharedDomainNormalizedMaxError
```

These quantities describe predictive sensitivity and are used as secondary ranking diagnostics. No new arbitrary hard threshold was introduced.

### Model-selection interpretation

The selected model is conditional on:

- configured candidate models;
- bounds and fitting configuration;
- preprocessing and deformation range;
- the observed specimen response.

It is not presented as a uniquely proven constitutive law.

## Individual, population, and future joint characterization

Three responsibilities are intentionally separated.

### A. Individual-study workflows

Tension and compression each retain:

- per-specimen processed curves and mechanical metrics;
- per-specimen model fitting and selection;
- parameters and fitting audit results;
- per-study population summaries;
- maintained figures, CSV files, MAT files, and reports.

These outputs remain useful when only one test mode is available. They must not be removed merely because a future joint characterization workflow exists.

Root population exports retain explicit individual-selection names:

```text
individual_selected_model_parameter_values.csv
individual_selected_model_parameter_summary.csv
```

### B. Individual model selection

Model selection remains specimen-specific within each test mode. Tension and compression are not combined to choose an individual specimen model.

The current revision improves this workflow by separating parameter sensitivity from model eligibility and adding response sensitivity across fitting windows.

### Consensus-model population

The optional existing material-level workflow remains distinct:

1. reads individual standard-workflow selections;
2. determines the majority model using configured candidate order as deterministic tie-break;
3. refits every retained specimen using that consensus model;
4. summarizes consensus-model parameters and equivalent initial shear modulus.

Maintained function:

```matlab
batch = mechanics.workflow.fitConsensusModelAcrossSpecimens( ...
    specimens, individualSelectedModels, candidateModelNames, ...
    fitConfig, batchConfig);
```

Outputs remain under:

```text
consensus-model-population/
```

`compareModelsAcrossSpecimens` remains a separate optional diagnostic workflow.

### C. Future joint material characterization

A future workflow may jointly characterize independent tension and compression datasets. It must:

- consume already processed specimen-level curves;
- accept unpaired specimens;
- begin with tension and compression without hard-coding those as the only future modes;
- balance modes and specimens explicitly;
- produce joint material parameters and mode-specific predictions;
- preserve A and B outputs without duplication;
- avoid wrappers, aliases, and bridge files unless a real shared contract is demonstrated.

This workflow is not implemented in the current pull request.

## Constitutive model findings

The real-data audit supports retaining the existing Yeoh-3 definition:

```text
C10, C20, C30
```

Yeoh-2 may be evaluated later as a separate registered model, but `yeoh` must not be silently redefined.

For the reviewed real data:

- Yeoh-3 strongly outperformed Neo-Hookean and Mooney-Rivlin in full-window RMSE and BIC;
- Yeoh-3 remained predictively stable within shared fitting-window domains;
- Mooney-Rivlin commonly collapsed toward Neo-Hookean because `C01` was approximately zero;
- parameter magnitude alone was not used to judge physical contribution.

## Reporting and figure export

Maintained reports:

```matlab
mechanics.io.exportTensileStudyReport
mechanics.io.exportCompressionStudyReport
mechanics.io.exportConstitutiveStudyReport
```

The fitting audit is part of the primary study reports. It reads stored fitting results and does not refit models during report generation.

The model-summary audit reports:

- window success and convergence counts;
- full-window RMSE, R-squared, AIC, and BIC;
- relative parameter CV and dominant CV parameter;
- parameter sign changes;
- shared-domain normalized response sensitivity;
- eligibility and selected status.

Reports state that parameter CV and response sensitivity are diagnostics and do not independently determine eligibility.

Maintained workflow figures are exported through `mechanics.plotting.exportFigureFiles` as PNG and FIG. Manual figures created directly in study drivers remain outside this persistence contract.

## Units and presentation

Processed strain remains dimensionless in stored data:

```text
-
```

Maintained axes and reports present strain as:

```text
mm/mm
```

This is presentation-only. Other units are resolved from processed specimen metadata with maintained fallbacks.

## Validation completed for the current branch

Focused suites passed:

```matlab
focusedResults = runtests([
    "tests/test_model_selection.m"
    "tests/test_selected_parameter_population.m"
    "tests/test_batch_model_comparison.m"
    "tests/test_study_reporting.m"
    "tests/test_compression_study.m"
]);
```

The complete suite also passed:

```matlab
results = run_all_tests();
assert(all([results.Passed]), "Repository tests failed.")
```

The maintained real tensile and compression drivers were rerun. Regenerated MAT files confirmed that `selectionConfig` no longer stores `maximumRelativeParameterCV`. The reports and selection outputs were reviewed and Yeoh was selected consistently for the reviewed retained specimens.

## Deferred findings and next priorities

1. After the current pull request is merged, update local `main` and do not continue on the merged branch.
2. Audit selected-model and consensus-population statistics for `SampleCount < 2`; decide whether dispersion and inference fields should become `NaN` or carry an explicit insufficient-count status.
3. Audit Issue #25 and define a limited contract for tensile-study comparison report export.
4. Review whether consensus should remain a simple majority vote or require a stronger material-level criterion, while preserving individual selection and consensus refitting as separate responsibilities.
5. Define the first limited phase for joint tension-compression material characterization described under C.
6. Possible additions such as Yeoh-2 or Ogden remain deferred and must be introduced as explicit registered models with tests and documentation.

Prefer a small next phase. Do not combine the `SampleCount`, comparison-report, consensus-policy, new-model, and joint-characterization objectives in one change.

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
- Maintain relevant, nonredundant outputs by default.
- Do not extract shared driver helpers merely because scripts have similar syntax.
- Do not merge a pull request unless explicitly requested.

## Closing a work session

Record the selected scope, branch, latest commit SHA, tests executed, documentation changes, unresolved findings, and next concrete objective here only when the information is expected to remain useful beyond the current chat.
