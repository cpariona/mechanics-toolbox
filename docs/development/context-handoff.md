# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Validated merged baseline

The current merged baseline is PR #37:

```text
e545862f7a16fed489cd9c72dc2f03609f20b3df
```

It includes:

- maintained tensile and compression studies and drivers;
- shared uniaxial processing, fitting, diagnostics, populations, and reporting;
- specimen-specific model selection;
- consensus-model population refitting as a separate optional workflow;
- small-sample population summaries with non-estimable dispersion reported as `NaN`;
- tensile-study comparison export and reporting;
- the canonical phased plan for joint material characterization.

## Current branch

The active branch is:

```text
feature/joint-characterization-input-contract
```

It implements phase C1 only: joint-characterization configuration, registered tension/compression mode contracts, normalization of completed studies, and behavioral tests. It does not perform fitting, model selection, export, or driver execution.

Focused tests and the complete `run_all_tests()` suite passed.

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

Instrument polarity may vary. Compression processing normalizes processed results to the physical negative-compression contract. Presentation may show positive magnitudes without changing stored state.

## Constitutive fitting and model selection

The standard individual workflow fits every configured model over nested fitting windows, stores every fitting result, and uses the full-window fit for final RMSE, R-squared, AIC, and BIC.

Current registered models:

```text
neo-hookean
mooney-rivlin
yeoh
```

The current `yeoh` model is Yeoh-3:

```text
C10, C20, C30
```

Do not silently redefine it as Yeoh-2. Additional constitutive models must be explicit model-registry entries with their own tests and documentation.

Parameter CV and sign changes are diagnostics. They do not independently determine model eligibility. Shared-domain prediction sensitivity across fitting windows remains a secondary ranking diagnostic.

## A, B, and C responsibilities

### A. Individual-study workflows — implemented

Tension and compression retain:

- processed curves and mechanical metrics per specimen;
- individual constitutive fits and selected models;
- fitting-audit results;
- per-study population summaries;
- CSV, MAT, figures, and reports.

These outputs remain valid when only one experimental mode is available and must not be removed by later material-level workflows.

### B. Individual model selection and consensus population — implemented

Model selection remains specimen-specific within each mode.

The optional consensus-model workflow remains distinct:

1. read individual selections;
2. determine a majority model using deterministic configured ordering;
3. refit every retained specimen with that model;
4. summarize common-model parameters and equivalent initial shear modulus.

This is not joint tension-compression characterization.

### C. Joint material characterization — in progress

C estimates one constitutive parameter set from independent experimental modes. The initial real modes are uniaxial tension and uniaxial compression. Specimens are independent and unpaired.

Canonical design document:

```text
docs/workflows/joint-material-characterization.md
```

Planned final entrypoint:

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

Only tension and compression are currently supported by real physical contracts. Do not add unsupported biaxial, shear, torsion, or other implementations merely to demonstrate extensibility.

## C1 — Input normalization and mode contract: completed

Implemented configuration:

```matlab
config = mechanics.config.jointMaterialCharacterizationConfig();
```

Implemented mode registry:

```matlab
mode = mechanics.workflow.jointCharacterizationModeRegistry(modeName);
```

Implemented normalizer:

```matlab
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
```

Accepted initial use:

```matlab
studies = {tensileStudy, compressionStudy};
modeNames = ["tension"; "compression"];
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
```

The normalizer:

- consumes completed studies only;
- reads processed specimen records without reprocessing;
- accepts unequal numbers of tension and compression specimens;
- preserves each specimen's sampling grid;
- preserves negative compression deformation and stress;
- maps processed engineering/true measures to the existing constitutive-model context;
- validates configured strain and stress unit compatibility;
- namespaces global specimen identifiers while retaining original identifiers;
- creates no synthetic pairing;
- rejects incomplete studies, unsupported modes, invalid weights, empty modes, and invalid observations.

The normalized result contains:

```text
normalized.modeNames
normalized.modeWeights
normalized.specimens
normalized.modeSummary
normalized.specimenCount
normalized.observationCount
normalized.config
normalized.createdAt
```

Each normalized specimen contains:

```text
Mode
StudyIndex
OriginalSpecimenId
SpecimenId
Deformation
MeasuredStress
Context
StrainUnit
StressUnit
ObservationCount
```

C1 does not perform joint fitting.

## C1 validation

Focused tests passed:

```matlab
focusedResults = runtests([
    "tests/test_joint_characterization_input_contract.m"
    "tests/test_tensile_study.m"
    "tests/test_compression_study.m"
    "tests/test_constitutive_models.m"
]);
```

The complete suite also passed:

```matlab
results = run_all_tests();
assert(all([results.Passed]), "Repository tests failed.")
```

C1 validation is synthetic because it defines a structural input contract and does not estimate material parameters.

## C2 — Fixed-model joint fitting: next objective

C2 must remain limited to fitting one configured registered model to the C1 normalized input.

Required behavior:

- reuse registered model evaluation and existing optimization infrastructure where contracts match;
- implement a hierarchical objective:
  1. normalized loss per specimen;
  2. average across specimens within each mode;
  3. weighted average across modes;
- default to equal influence per specimen within each mode and equal total influence for tension and compression;
- begin with response-range normalization using a finite stress scale per specimen;
- retain unnormalized residuals and physical RMSE alongside normalized objective values;
- retain total, per-mode, and per-specimen diagnostics and predictions;
- validate recovery of known parameters using synthetic tension and compression generated by the existing model registry.

C2 must not add:

- multi-model fitting or model selection;
- driver scripts;
- CSV, MAT, report, or figure exports;
- new constitutive models;
- unsupported experimental modes.

C2 establishes the physical and numerical objective before C3 introduces comparison across all registered models.

## Later C phases

### C3 — Multi-model fitting and joint selection

- fit every configured registered model using the C2 objective;
- define joint eligibility, practical equivalence, parsimony, information-criterion use, and deterministic tie-breaking;
- select one joint model without changing individual selections from A and B;
- test failed candidates, ties, and generating-model recovery.

### C4 — Maintained driver, reporting, and outputs

- add `studies/joint-characterization/run_joint_material_characterization.m`;
- load completed tensile and compression MAT studies;
- export nonredundant CSV, MAT, Markdown, and mode-specific figures under `results/joint-material-characterization/`;
- validate against the available independent real tension and compression studies.

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

- audit sensitivity to mode weights, normalization, sampling density, and deformation range;
- add alternatives only when evidence supports them;
- verify that a future real mode can be added through the mode contract without editing unrelated fitting, ranking, export, and plotting code;
- review whether joint selection requires window sensitivity or cross-validation.

## Deferred decisions outside C2

1. whether the existing single-mode consensus policy should remain majority-based;
2. whether Yeoh-2 should be added as a separate registered model;
3. whether Ogden or other models should be added;
4. real validation of two-study tensile comparison export when suitable data become available;
5. additional experimental modes beyond tension and compression.

Do not combine these objectives with C2.

## Read first

1. `docs/development/context-handoff.md`
2. `docs/workflows/joint-material-characterization.md`
3. `docs/development/repository-structure.md`
4. `docs/development/testing.md`
5. `docs/workflows/tensile-study.md`
6. `docs/workflows/compression-study.md`
7. `docs/workflows/constitutive-analysis.md`
8. `docs/reference/constitutive-models.md`
9. implementation required by the active C phase only

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

Confirm local `main` matches `origin/main` and the working tree is clean. Do not continue work on a branch after its pull request has been merged.

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
- Do not create bridge files merely to make workflows appear symmetrical.
- Add files only when they represent a distinct maintained contract.
- Maintain relevant, nonredundant outputs by default.
- Do not extract shared driver helpers merely because scripts have similar syntax.
- Use the model registry rather than model-name conditionals when parameter and evaluation contracts are shared.
- Do not merge a pull request unless explicitly requested.

## Closing C1

Before merging this branch:

1. review the final diff;
2. open a PR against `main`;
3. state that focused and complete MATLAB suites passed;
4. state explicitly that C1 performs no fitting;
5. after merge, update local `main`, remove the merged branch, and create a separate C2 branch.