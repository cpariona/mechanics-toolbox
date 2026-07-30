# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Validated merged baseline

The current merged baseline is PR #36:

```text
5b111e5c9029a98855c9434b8ca28b3f993bba5c
```

It includes:

- maintained tensile and compression study workflows and drivers;
- shared uniaxial processing, constitutive fitting, diagnostics, and reporting;
- specimen-specific model selection;
- consensus-model population refitting as a distinct optional workflow;
- fitting-window audit and predictive-sensitivity diagnostics;
- small-sample population summaries that report non-estimable dispersion as `NaN` when `SpecimenCount < 2`;
- cleaned repository branches and maintained documentation structure.

## Current branch and completed scope

The active branch is:

```text
audit/tensile-comparison-report
```

It implements Issue #25 through:

```matlab
files = mechanics.io.exportTensileStudyComparison( ...
    comparison, outputFolder);
```

The exporter consumes an existing result from:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    studies, groupLabels, config);
```

It writes:

```text
study_summary.csv
study_compatibility.csv
pairwise_metric_comparison.csv
pairwise_curve_comparison.csv
tensile_study_comparison.png
tensile_study_comparison.fig
tensile_study_comparison.mat
tensile_study_comparison.md
```

The exporter does not recalculate comparison statistics, duplicate individual study bundles, or include constitutive-parameter and consensus-model reporting.

Focused tests and the complete `run_all_tests()` suite passed. Validation used synthetic completed tensile studies. A representative pair of real tensile study datasets is not currently available, so real two-study comparison validation remains explicitly pending and is not required to close this limited implementation.

Documentation updated on this branch:

```text
docs/README.md
docs/development/context-handoff.md
docs/development/repository-structure.md
docs/workflows/tensile-study.md
docs/workflows/joint-material-characterization.md
```

## Maintained individual-study entrypoints

```matlab
tensileStudy = mechanics.workflow.runTensileStudy(inputValue, config);
compressionStudy = mechanics.workflow.runCompressionStudy(inputValue, config);
```

Maintained real-experiment drivers:

```text
studies/tension/run_tensile_experiment.m
studies/compression/run_compression_experiment.m
```

The drivers retain experiment-specific paths, exclusions, assumptions, settings, optional analyses, and manual inspection figures. Reusable implementation belongs under `src/+mechanics`.

## Shared uniaxial contract

Tension and compression share maintained implementations for:

- normalized processed specimen structures;
- engineering and true strain/stress measures;
- area evolution;
- tangent-modulus estimation;
- constitutive fitting and model selection;
- uncertainty and fit diagnostics;
- population aggregation and group comparison;
- unit-aware plotting and maintained figure export.

Mode-specific processing remains separate:

- tension: loading segmentation, peak, post-peak, and fracture-oriented descriptors;
- compression: cycle selection, loading/unloading branches, contact-oriented preprocessing, hysteresis, and cycle diagnostics.

Stored mechanical signs remain physical:

```text
tension:     displacement > 0, strain > 0, stress > 0, stretch > 1
compression: displacement < 0, strain < 0, stress < 0, 0 < stretch < 1
```

Instrument polarity may vary. Compression processing normalizes processed results to the physical negative-compression contract. Presentation may show compression magnitudes without changing stored values.

## Constitutive fitting and model selection

The standard individual workflow fits every configured model over nested fitting windows, stores every result, and uses the full-window fit for final RMSE, R-squared, AIC, and BIC.

Current default candidate models:

```text
neo-hookean
mooney-rivlin
yeoh
```

The current `yeoh` model is Yeoh-3:

```text
C10, C20, C30
```

Do not silently redefine it as Yeoh-2. Additional models must be explicit model-registry entries with independent tests and documentation.

Parameter CV and sign changes are diagnostics. They do not independently determine eligibility. Shared-domain prediction sensitivity across fitting windows is retained as a secondary ranking diagnostic.

The selected individual model is conditional on candidate models, bounds, preprocessing, deformation range, and the observed specimen response. It is not presented as a uniquely proven constitutive law.

## A, B, and C responsibilities

### A. Individual-study workflows — implemented

Tension and compression retain:

- processed curves and mechanical metrics per specimen;
- individual constitutive fits and selected models;
- fitting audit results;
- per-study population summaries;
- CSV, MAT, figures, and reports.

These outputs remain valid when only one experimental mode is available and must not be removed by later material-level workflows.

### B. Individual model selection and consensus population — implemented

Model selection remains specimen-specific within each mode.

The optional consensus-model workflow remains distinct:

1. read individual selections;
2. determine a majority model with deterministic configured ordering;
3. refit every retained specimen with that model;
4. summarize common-model parameters and equivalent initial shear modulus.

This is not joint tension-compression characterization.

### C. Joint material characterization — next substantive objective

C will estimate one constitutive parameter set from independent experimental modes. The initial real modes are uniaxial tension and uniaxial compression. Specimens are not paired.

Canonical design document:

```text
docs/workflows/joint-material-characterization.md
```

Planned public entrypoint:

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

Planned maintained driver:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

The driver will consume completed study MAT files or in-memory study results. It must not re-import raw data or duplicate the tension and compression drivers.

C must:

- accept unpaired specimen counts;
- preserve mode-specific physical signs and contexts;
- balance specimens within modes and modes within the joint objective;
- fit every configured model available through the model registry;
- select the best eligible joint model using an explicit joint ranking contract;
- retain total, per-mode, and per-specimen metrics and predictions;
- preserve A and B outputs without duplication;
- remain structurally extensible to future real modes and registered constitutive models.

Only tension and compression are currently supported by real data. Do not add unsupported biaxial, shear, torsion, or other mode implementations merely to demonstrate extensibility.

## C implementation phases

### C1 — Input normalization and mode contract

- Add `jointMaterialCharacterizationConfig` with candidate models, normalization, weighting, fitting, and export sections.
- Normalize completed studies into one canonical observation structure.
- Define the minimum registered mode adapter contract required for tension and compression.
- Preserve mode, study, and specimen identities without synthetic pairing.
- Validate signs, measures, units, duplicate IDs, unpaired counts, and unsupported modes.

C1 does not perform joint fitting.

### C2 — Fixed-model joint fitting

- Fit one configured registered model to all normalized specimens.
- Reuse model evaluation and multistart optimization where contracts match.
- Use a hierarchical objective: normalized loss per specimen, average within mode, then weighted average across modes.
- Default to equal influence per specimen within mode and equal total influence for tension and compression.
- Retain normalized and physical residual metrics by specimen and mode.
- Validate parameter recovery with synthetic tension and compression generated from known parameters.

C2 establishes the numerical and physical objective before model comparison.

### C3 — Multi-model fitting and joint selection

- Fit every configured registered candidate model using the C2 objective.
- Define joint eligibility, practical equivalence, parsimony, information-criterion use, and deterministic tie-breaking.
- Select one joint model without changing individual selections from A and B.
- Test failed candidates, ties, parameter recovery, and cases where the generating model is present or absent.

Adding a future constitutive model should require model registration and model-specific tests, not changes to joint orchestration.

### C4 — Maintained driver, reporting, and outputs

- Add `studies/joint-characterization/run_joint_material_characterization.m`.
- Load completed tensile and compression studies.
- Export a nonredundant bundle under `results/joint-material-characterization/`.
- Add mode-specific joint-fit figures, CSV summaries, MAT persistence, and a Markdown report.
- Validate against the available independent real tensile and compression studies.

Planned bundle:

```text
joint_material_characterization.mat
candidate_model_summary.csv
selected_joint_parameters.csv
mode_fit_summary.csv
specimen_fit_summary.csv
joint_material_characterization.md
joint_fit_tension.png
joint_fit_tension.fig
joint_fit_compression.png
joint_fit_compression.fig
```

### C5 — Robustness and extensibility audit

- Audit sensitivity to mode weights, specimen normalization, sampling density, and deformation range.
- Add alternative weighting or normalization only when evidence supports it.
- Verify that a future mode can be added through the mode contract without editing unrelated fitting, ranking, export, and plotting code.
- Review whether joint selection needs window sensitivity or cross-validation.

C5 must not implement experimental modes for which no physical contract or data exist.

## Remaining deferred decisions

These are not part of the initial C1 implementation:

1. whether the existing single-mode consensus policy should remain majority-based;
2. whether Yeoh-2 should be added as a separate registered model;
3. whether Ogden or other models should be added;
4. real validation of two-study tensile comparison export when suitable data become available;
5. additional experimental modes beyond tension and compression.

Do not combine these objectives with C1.

## Validation protocol

For each C phase:

1. run focused behavioral tests;
2. run the complete repository suite;
3. inspect generated tables, MAT structures, reports, and figures when outputs are introduced;
4. validate with synthetic recovery data before interpreting real-data results;
5. record limitations explicitly when representative real data are unavailable.

Current branch validation already completed:

```matlab
results = run_all_tests();
assert(all([results.Passed]), "Repository tests failed.")
```

## Read first

1. `docs/development/context-handoff.md`
2. `docs/workflows/joint-material-characterization.md`
3. `docs/development/repository-structure.md`
4. `docs/development/testing.md`
5. `docs/workflows/tensile-study.md`
6. `docs/workflows/compression-study.md`
7. `docs/workflows/constitutive-analysis.md`
8. `docs/reference/constitutive-models.md`
9. implementation required by the selected C phase only

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

Confirm local `main` matches `origin/main` and the working tree is clean. Do not continue work on a branch after its PR has been merged.

Repository checks:

```bash
git diff --check
git status -sb
git status --ignored -s
git ls-files --others --exclude-standard
```

## Maintenance rules

- Share implementation only when physical and data contracts are genuinely common.
- Keep import normalization, stored mechanics, fitting-window direction, and presentation conventions separate.
- Keep reusable code under `src/+mechanics`, experiment drivers under `studies`, examples under `examples`, and tests under `tests`.
- Do not preserve obsolete APIs through wrappers or aliases.
- Do not create bridge files merely to make two workflows look symmetrical.
- Add files only when they represent a distinct maintained contract.
- Maintain relevant, nonredundant outputs by default.
- Do not extract shared driver helpers merely because scripts have similar syntax.
- Use the model registry rather than model-name conditionals when parameter and evaluation contracts are shared.
- Do not merge a pull request unless explicitly requested.

## Closing the current phase

Before merging the tensile-comparison export branch:

1. review the final diff;
2. open a PR against `main`;
3. state that focused and complete tests passed using synthetic completed studies;
4. state that real paired-study validation was unavailable;
5. close Issue #25 after the PR is merged;
6. update local `main`, remove the merged branch, and create a new branch for C1.
