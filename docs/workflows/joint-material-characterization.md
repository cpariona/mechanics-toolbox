# Joint material characterization

## Purpose

Joint material characterization estimates one constitutive parameter set from independent experimental modes while preserving the maintained per-mode studies and their individual model-selection results.

The first supported modes will be uniaxial tension and uniaxial compression. Specimens are not required to be paired. The design must remain extensible to additional modes without introducing placeholder implementations for modes that do not yet exist.

This workflow is distinct from:

- individual specimen fitting and model selection;
- per-study population summaries;
- majority-model consensus refitting within one study mode;
- comparison of experimental groups within the same mode.

## Design principles

- Consume completed, already processed studies. Do not re-import or reprocess raw data.
- Preserve tension and compression sign, measure, unit, and context contracts.
- Balance specimens within modes and modes within the objective explicitly.
- Fit every registered candidate model supplied by configuration and select the best eligible joint model.
- Reuse the model registry, model evaluation, multistart fitting, fit metrics, and ranking concepts when their contracts are genuinely shared.
- Keep joint orchestration and joint result ownership explicit. Do not add wrappers, aliases, compatibility entrypoints, or bridge files.
- Preserve all relevant A and B outputs; joint characterization adds a new material-level result rather than replacing them.

## Planned maintained entrypoint

The planned public workflow is:

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

Initial use:

```matlab
studies = [tensileStudy, compressionStudy];
modeNames = ["tension", "compression"];
config = mechanics.config.jointMaterialCharacterizationConfig();
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

The API must accept independent studies with different specimen counts. A future additional mode should be introduced by registering a mode adapter with a real physical contract, not by expanding a tension/compression conditional throughout the implementation.

## Planned driver

The maintained experiment driver will be:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

The driver will configure:

- input MAT files or completed in-memory study results;
- included modes and specimens;
- candidate constitutive models;
- weighting and normalization;
- fitting bounds and multistart settings;
- output and report folders;
- optional inspection figures.

Reusable fitting, selection, plotting, and export logic remains under `src/+mechanics`.

## Input contract

Each accepted study must provide processed specimen records sufficient to build a joint observation table containing:

```text
Mode
StudyIndex
SpecimenId
Deformation
MeasuredStress
Context
StrainUnit
StressUnit
```

The normalization stage must:

- retain the original mode and specimen identifiers;
- reject incompatible deformation or stress measures that cannot be evaluated by the candidate model;
- retain physical compression signs internally;
- avoid forcing tension and compression onto one shared deformation grid;
- create no synthetic pairing between specimens.

## Joint objective

A raw concatenated pointwise RMSE is not acceptable because it allows modes, specimens, or sampling densities to dominate accidentally.

For each candidate model, the initial objective will use three levels:

1. compute a normalized loss for each specimen;
2. average specimen losses within each mode;
3. average mode losses using explicit configured mode weights.

The default must give equal total influence to tension and compression and equal influence to specimens within each mode. Point count must not determine material influence.

Normalization must use a documented finite stress scale per specimen. The implementation should support a small set of explicit strategies, beginning with response-range normalization. Additional strategies should only be added when justified by real data.

The result must retain the unnormalized residuals and fit metrics so the normalized objective is not mistaken for physical error magnitude.

## Candidate models and selection

Joint characterization must fit every model listed in configuration. The initial default candidates will be the currently registered uniaxial models:

```text
neo-hookean
mooney-rivlin
yeoh
```

The implementation must obtain parameter names, bounds, evaluation, and parameter count from the existing model registry. It must not hard-code model-specific fitting branches outside the registry contract.

For each candidate, retain:

- parameters and convergence status;
- total joint objective;
- per-mode normalized loss;
- per-specimen normalized and physical metrics;
- mode-specific predictions;
- parameter count, AIC, and BIC where their sample-size contract is valid;
- multistart diagnostics.

Selection should follow the repository's existing principles: eligibility first, practical fit equivalence, parsimony, configured information criterion, and explicit diagnostics. The exact joint ranking contract must be defined and tested in its own phase rather than inherited implicitly from individual model selection.

## Result contract

The planned result will contain:

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

`selectedFit` must contain the common parameter set and predictions separated by mode and specimen.

## Planned outputs

The maintained output folder will use:

```text
results/joint-material-characterization/
```

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

Additional mode figures should follow the same naming rule when real modes are added. The joint bundle must not copy complete tensile or compression study outputs.

## Implementation phases

### Phase C1 — Input normalization and mode registry

- Define `jointMaterialCharacterizationConfig` with candidate models, mode weights, specimen weighting, normalization, fitting, and export sections.
- Define one canonical normalization workflow that consumes completed studies.
- Introduce the minimum mode registry or adapter contract required for tension and compression.
- Produce a normalized observation structure without fitting.
- Add synthetic tests for unpaired counts, duplicate specimen IDs, signs, units, measures, and unsupported modes.

No driver, fitting, selection, or export is added in C1 unless required to validate the input contract.

### Phase C2 — Fixed-model joint fitting

- Implement joint fitting for one configured registered model.
- Reuse model evaluation and multistart optimization.
- Implement equal-mode and equal-specimen weighting with explicit normalization.
- Retain total, per-mode, and per-specimen diagnostics.
- Test parameter recovery with synthetic tension and compression generated from known parameters.

C2 establishes the physical and numerical objective before model comparison is introduced.

### Phase C3 — Multi-model fitting and joint selection

- Fit all configured registered models using the C2 contract.
- Define joint eligibility and ranking explicitly.
- Select the best joint model without altering individual specimen selections.
- Add tests for deterministic tie-breaking, failed candidates, parsimony, and recovery when the generating model is in the registry.

Adding another constitutive model later should require registration and model-specific tests, not changes to the joint orchestration.

### Phase C4 — Maintained driver and result bundle

- Add `studies/joint-characterization/run_joint_material_characterization.m`.
- Load completed tensile and compression MAT studies without reprocessing raw data.
- Add maintained CSV, MAT, Markdown, and figure exports.
- Document driver configuration and output ownership.
- Validate with available real tensile and compression studies, while stating that the specimens are independent and unpaired.

### Phase C5 — Robustness and extensibility audit

- Audit sensitivity to mode weights, specimen normalization, sampling density, and deformation range.
- Add optional mode-weight configurations only when evidence supports them.
- Verify that a new mode can be added through the mode contract without editing unrelated fitting and reporting code.
- Review whether joint model-selection diagnostics need window sensitivity or cross-validation.

C5 must not add unsupported experimental modes merely to demonstrate extensibility.

## Current validation limitation

Only uniaxial tension and compression are currently available. Therefore:

- the initial implementation will support exactly those two real mode contracts;
- extensibility will be structural and tested with registered synthetic adapters only when necessary;
- claims about biaxial, shear, torsion, or other modes will remain deferred until data and physical contracts exist;
- validation of the full workflow will use synthetic recovery tests and the available independent tension and compression studies.
