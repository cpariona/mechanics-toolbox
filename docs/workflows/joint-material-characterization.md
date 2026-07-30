# Joint material characterization

## Purpose

Joint material characterization estimates one constitutive parameter set from independent experimental modes while preserving the maintained per-mode studies and their individual model-selection results.

The first supported modes are uniaxial tension and uniaxial compression. Specimens are independent and are not required to be paired. The design remains structurally extensible to additional modes without placeholder implementations for modes that do not yet have a physical contract and data.

This workflow is distinct from:

- individual specimen fitting and model selection;
- per-study population summaries;
- majority-model consensus refitting within one study mode;
- comparison of experimental groups within the same mode.

## Design principles

- Consume completed, already processed studies. Do not re-import or reprocess raw data.
- Preserve tension and compression signs, measures, units, and constitutive contexts.
- Balance specimens within modes and modes within the objective explicitly.
- Fit every registered candidate model supplied by configuration and select the best eligible joint model.
- Reuse the model registry, model evaluation, multistart fitting, fit metrics, and ranking concepts only where their contracts genuinely match.
- Keep joint orchestration and result ownership explicit. Do not add wrappers, aliases, compatibility entrypoints, or bridge files.
- Preserve all relevant individual-study and individual-selection outputs. Joint characterization adds a material-level result rather than replacing them.

## Planned maintained entrypoint

The final public workflow remains planned as:

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

Initial use will accept heterogeneous completed study results through a cell array:

```matlab
studies = {tensileStudy, compressionStudy};
modeNames = ["tension"; "compression"];
config = mechanics.config.jointMaterialCharacterizationConfig();
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

The API must accept different specimen counts. A future mode must be introduced through a real registered mode contract rather than by expanding tension/compression conditionals throughout the fitting, reporting, and export implementation.

## Maintained configuration

C1 introduced:

```matlab
config = mechanics.config.jointMaterialCharacterizationConfig();
```

The configuration owns:

```text
candidateModelNames
modeNames
modeWeights
specimenWeighting
normalization
requireFiniteObservations
requireMatchingStressUnits
requireMatchingStrainUnits
fitting
export
```

The initial registered candidate models are:

```text
neo-hookean
mooney-rivlin
yeoh
```

C1 does not consume the fitting and export sections yet. They are retained because they belong to the final joint workflow configuration rather than to separate compatibility configurations.

## Implemented input normalization

C1 introduced the maintained normalizer:

```matlab
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
```

It consumes completed studies and returns:

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

The canonical global specimen identifier is namespaced by mode and study, while the original specimen identifier remains available. Duplicate identifiers across independent studies therefore do not collide and are not interpreted as paired specimens.

The normalizer:

- accepts completed tension and compression studies with unequal specimen counts;
- reads only records whose status is `processed`;
- preserves each specimen's original sampling grid;
- preserves negative compression deformation and stress;
- removes no finite observations unless required by the explicit finite-observation contract;
- validates deformation and stress measures against model-evaluable contexts;
- validates configured strain and stress unit compatibility;
- creates no synthetic pairing or shared interpolation grid;
- rejects incomplete studies, empty modes, duplicate mode names, invalid mode weights, and unsupported modes.

Processed measures are mapped to the existing constitutive-model context:

```text
engineering strain -> engineering-strain
true strain        -> true-strain
engineering stress -> nominal
true stress        -> cauchy
```

## Implemented mode registry

C1 introduced:

```matlab
mode = mechanics.workflow.jointCharacterizationModeRegistry(modeName);
```

The initial real mode contracts are:

```text
tension
compression
```

Each contract defines its canonical name, expected study test type, deformation and stress fields, and expected physical signs. Unsupported modes are rejected explicitly. No biaxial, shear, torsion, or synthetic placeholder mode is registered.

## Joint objective

A raw concatenated pointwise RMSE is not acceptable because it allows modes, specimens, or sampling densities to dominate accidentally.

C2 will implement a three-level objective:

1. compute a normalized loss for each specimen;
2. average specimen losses within each mode;
3. average mode losses using explicit configured mode weights.

The default must give equal total influence to tension and compression and equal influence to specimens within each mode. Point count must not determine material influence.

The first normalization strategy will be response-range normalization using a finite stress scale per specimen. The result must also retain unnormalized residuals and physical fit metrics.

## Candidate models and selection

C3 will fit every configured registered model. Parameter names, bounds, evaluation functions, and parameter counts must come from the existing model registry. Joint orchestration must not introduce model-specific fitting branches where the registry already provides the shared contract.

For each candidate, retain:

- parameters and convergence status;
- total joint objective;
- per-mode normalized loss;
- per-specimen normalized and physical metrics;
- mode-specific predictions;
- parameter count, AIC, and BIC where their sample-size contract is valid;
- multistart diagnostics.

The exact joint eligibility and ranking contract will be defined in C3 rather than inherited implicitly from individual model selection.

## Planned result contract

The complete result is planned to contain:

```text
result.modeNames
result.specimens
result.candidates
result.selectedModelName
result.selectedFit
result.modeSummary
result.specimenSummary
result.config
result.createdAt
```

`selectedFit` will contain one common parameter set and predictions separated by mode and specimen.

## Planned driver and outputs

The maintained experiment driver will be:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

It will load completed tensile and compression MAT studies or accept already loaded results. It will not re-import raw data or duplicate the individual study drivers.

The planned nonredundant bundle is:

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

Additional mode figures will follow the same naming rule only when real mode contracts are added. The joint bundle must not copy complete tensile or compression study outputs.

## Implementation phases

### C1 — Input normalization and mode registry: completed

Implemented:

- `mechanics.config.jointMaterialCharacterizationConfig`;
- `mechanics.workflow.jointCharacterizationModeRegistry`;
- `mechanics.workflow.normalizeJointCharacterizationStudies`;
- synthetic behavioral tests for unpaired counts, duplicate IDs, physical signs, units, measures, mode weights, incomplete studies, and unsupported modes.

C1 performs no fitting, model selection, driver execution, or export.

### C2 — Fixed-model joint fitting: next

- Fit one configured registered model to all normalized specimens.
- Reuse model evaluation and multistart optimization where contracts match.
- Implement equal-mode and equal-specimen weighting with explicit response-range normalization.
- Retain total, per-mode, and per-specimen normalized and physical diagnostics.
- Test parameter recovery using synthetic tension and compression generated from known parameters.

C2 establishes the physical and numerical objective before model comparison is introduced.

### C3 — Multi-model fitting and joint selection

- Fit all configured registered models using the C2 contract.
- Define joint eligibility and ranking explicitly.
- Select the best joint model without altering individual specimen selections.
- Test deterministic tie-breaking, failed candidates, parsimony, and generating-model recovery.

Adding another constitutive model later should require registration and model-specific tests, not changes to joint orchestration.

### C4 — Maintained driver and result bundle

- Add `studies/joint-characterization/run_joint_material_characterization.m`.
- Load completed tensile and compression MAT studies without reprocessing raw data.
- Add maintained CSV, MAT, Markdown, and figure exports.
- Document driver configuration and output ownership.
- Validate with available real independent tensile and compression studies.

### C5 — Robustness and extensibility audit

- Audit sensitivity to mode weights, specimen normalization, sampling density, and deformation range.
- Add alternative weighting or normalization only when evidence supports it.
- Verify that a new real mode can be added through the mode contract without editing unrelated fitting and reporting code.
- Review whether joint selection requires window sensitivity or cross-validation.

C5 must not add unsupported experimental modes merely to demonstrate extensibility.

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

Validation is synthetic because C1 is a structural input contract and performs no material fitting. Real-study execution becomes relevant in C2 and C4.

## Current limitation

Only uniaxial tension and compression are currently available. Therefore:

- the implementation supports exactly those two real mode contracts;
- extensibility remains structural rather than claimed experimentally;
- biaxial, shear, torsion, and other modes remain deferred until data and physical contracts exist;
- full validation will combine synthetic recovery tests with the available independent tension and compression studies.