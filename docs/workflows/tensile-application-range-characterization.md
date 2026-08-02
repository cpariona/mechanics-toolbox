# Tensile application-range characterization

## Status

Planned maintained add-on to the completed tensile-study workflow. No implementation exists yet.

## Purpose

This workflow will answer one limited constitutive question:

> Which supported hyperelastic model and reference parameter set best describe the processed uniaxial tensile loading response inside a user-defined application range?

The initial real use case is an engineering-strain interval such as `0 <= strain <= 0.30`, but the implementation must remain application-agnostic. OCE, OCT, Lamb waves, acoustoelasticity, incremental elasticity, wave inversion, and dispersion modelling are outside this repository and outside this phase.

## Architectural level

This capability is a maintained add-on to a completed tensile study. It is not another raw-data workflow and it is not equivalent in scope to joint tension-compression characterization.

```text
runTensileStudy
    -> completed tensile study
    -> runTensileApplicationRangeCharacterization
```

In parallel:

```text
completed tensile study + completed compression study
    -> runJointMaterialCharacterization
```

The tensile application-range workflow specializes one processed tensile trajectory. Joint characterization integrates independent modes to test whether one constitutive law represents them together.

## Required reuse

Before adding implementation, audit the existing tensile, constitutive-fitting, population, model-selection, reporting, and joint-characterization code.

Reuse existing functions when their physical and data contracts are genuinely identical, including where applicable:

- completed tensile-study normalization and specimen selection;
- deformation and stress conventions;
- model registry and model evaluation;
- bounded nonlinear fitting, multistart, limits, guesses, and diagnostics;
- equal-specimen population objectives;
- practical-equivalence and deterministic model-selection logic;
- parameter metadata and derived reference quantities;
- maintained figure export, tables, MAT persistence, and Markdown reporting.

Do not copy the tensile workflow, re-import raw files, reprocess specimens, or create parallel fitting infrastructure.

Do not force reuse of joint-characterization functions when their public contract requires multiple modes, mode weights, or mode normalization. Extract a shared lower-level function only when at least two maintained callers use the same physical contract. Do not create wrappers, aliases, bridge files, or helpers used by only one caller merely for symmetry.

## Proposed public contract

Preferred entrypoint:

```matlab
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);
```

Preferred configuration:

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.fitRange.deformationMeasure = "engineering-strain";
config.fitRange.minimum = 0;
config.fitRange.maximum = 0.30;
config.candidateModelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
```

The exact names may change during D1 only if repository conventions support a clearer, simpler contract. Avoid a generic name such as `runApplicationMaterialCharacterization`, because this workflow is explicitly subordinate to tension.

## Input contract

The workflow must consume one completed tensile-study result. It must not accept raw workbooks as an alternative path.

Validation should establish at least:

- completed tensile-study status;
- compatible tensile sign convention;
- compatible deformation and stress measures;
- finite processed loading curves;
- sufficient observations inside the configured range;
- consistent units and constitutive context across retained specimens.

The tensile workflow remains responsible for import, preprocessing, zero reference, segmentation, mechanical conversion, exclusions, specimen quality, and individual analysis.

## Range restriction

The workflow should characterize only the configured loading interval while preserving provenance.

Required behavior:

- use the already selected tensile loading response;
- retain the complete source curves by reference or source metadata;
- fit only observations inside the configured interval;
- do not rescale, clip, alter signs, or extrapolate observations;
- record the actual available and fitted range per specimen;
- record included and excluded observation counts;
- reject specimens that do not provide a valid fitted interval according to an explicit minimum-observation contract.

The first real configuration is expected to use engineering strain from `0` to `0.30`. The implementation must not hardcode this range.

## Population fitting contract

The workflow should estimate one parameter vector shared by all retained tensile specimens for each candidate model.

It must not create one application-range model per specimen or one model per deformation state.

Each specimen should have equal influence regardless of sampling density. Reuse the existing hierarchical objective when its single-mode contract is compatible. A pooled pointwise SSE that lets densely sampled specimens dominate is not acceptable.

The result should preserve per-specimen predicted stress and fit metrics for the selected and candidate models where existing contracts already do so.

## Model selection

Candidate models come from the maintained registry. Initial candidates are:

- Neo-Hookean;
- Mooney-Rivlin;
- Yeoh.

Selection must be parsimonious because a limited tensile range may not identify all parameters reliably.

Recommended policy:

1. reject failed or nonfinite fits;
2. apply existing reliability and identifiability evidence where maintained;
3. treat materially negligible objective improvements as practical equivalence;
4. prefer fewer parameters among practically equivalent reliable models;
5. use deterministic configured ordering only as the final tie-break;
6. report when the data do not distinguish candidate models strongly.

Do not select Yeoh merely because it produces the smallest numerical objective by a negligible margin.

## Reference properties

The selected result should expose reference quantities derived through the model registry, not through model-name conditionals in workflow, plotting, or export code.

For the currently registered incompressible models, the relevant reference shear modulus is:

```text
Neo-Hookean:   mu0 = mu
Mooney-Rivlin: mu0 = 2 * (C10 + C01)
Yeoh:          mu0 = 2 * C10
```

These are calibration-dependent estimates of one reference property. Results from full-range tension, compression, joint characterization, and the application range must not be presented as independent intrinsic shear moduli merely because their numerical estimates differ.

Incremental moduli, small-on-large tensors, and wave-related quantities are not part of this workflow.

## Sensitivity to fit range

A limited one-factor-at-a-time audit should evaluate whether the selected model and reference parameters are stable to the upper fit limit.

Initial real scenarios may include:

```matlab
config.audit.maximumDeformations = [0.20; 0.25; 0.30; 0.35];
```

The audit should reuse the same fitting and selection contract and report at least:

- maximum deformation;
- retained specimen and observation counts;
- selected model;
- objective;
- reference shear modulus when defined;
- selected-parameter relative change when model identity is unchanged;
- whether the selected model matches the baseline.

Do not introduce a broad robustness matrix without evidence. The approved scope is sensitivity to the application-range boundary.

## Optional compression validation

Compression may be supplied only as an optional external validation study.

The workflow should then:

1. fit and select the model using tensile data only;
2. evaluate that fixed model on compatible compression observations;
3. report prediction errors without refitting;
4. label the output explicitly as cross-mode validation.

Compression must not silently influence the primary tensile application-range fit. If compression is included in the fitting objective, that is joint material characterization and belongs to the existing joint workflow.

## Proposed result structure

Keep the result limited to information added by this analysis. Do not duplicate the complete source study.

```matlab
result.sourceStudyMetadata
result.fitRange
result.specimens
result.candidates
result.candidateSummary
result.selectedModelName
result.selectedFit
result.referenceProperties
result.windowAudit
result.validation
result.outputFiles
result.config
result.createdAt
```

Per-specimen information should include only fields needed to trace and evaluate the application-range fit, such as source ID, available range, fitted range, included/excluded counts, fitted observations, predictions, and maintained fit metrics.

## Proposed maintained outputs

Base bundle:

```text
tensile_application_range_characterization.mat
candidate_model_summary.csv
selected_parameters.csv
reference_properties.csv
specimen_fit_summary.csv
window_sensitivity.csv
tensile_application_range_characterization.md
tensile_application_range_fit.png
tensile_application_range_fit.fig
tensile_application_range_window_sensitivity.png
tensile_application_range_window_sensitivity.fig
```

Optional compression-validation outputs should be generated only when validation is enabled.

Figures should distinguish:

- complete source curves;
- observations inside the fitted range;
- population summary inside the common fitted domain;
- selected shared fit;
- selected model, parameters, and derived reference properties.

Use the maintained plotting and figure-export contracts. Do not add decorative or redundant figures.

## Proposed maintained driver

```text
studies/tension/run_tensile_application_range_characterization.m
```

The driver should load or receive a completed tensile study, configure the application range, execute the maintained workflow, and export results. It must not re-import raw workbooks or reproduce `run_tensile_experiment.m`.

The first real input is expected to be:

```text
results/real-tensile-study/tensile_study.mat
```

Optional validation may use:

```text
results/real-compression-study/compression_study.mat
```

Both paths remain local ignored data.

## Proposed implementation phases

### D1 — Reuse audit and contracts

- inspect completed tensile-study structures and maintained fitting/selection utilities;
- identify direct reuse and any genuinely shared lower-level contract;
- finalize config, input validation, result, and error identifiers;
- add behavioral tests for input and range contracts;
- do not implement fitting until the reuse decision is documented.

### D2 — Range-limited shared fitting

- extract retained processed tensile loading curves from the completed study;
- restrict observations to the configured interval;
- fit one shared parameter vector per candidate model;
- preserve equal-specimen influence and existing solver diagnostics;
- add synthetic parameter-recovery and sampling-density tests.

### D3 — Selection and reference properties

- reuse or generalize existing practical-equivalence and parsimonious ranking only where contracts match;
- expose registry-derived reference properties;
- test Neo-Hookean, Mooney-Rivlin, and Yeoh metadata without workflow model-name conditionals.

### D4 — Range sensitivity and optional validation

- implement the one-factor upper-range audit;
- add optional compression prediction without refitting;
- add comparison summaries without redefining multiple intrinsic `mu0` values.

### D5 — Driver, export, documentation, and real validation

- add the maintained driver and result bundle;
- update user documentation and repository indexes;
- run focused tests and `run_all_tests()`;
- execute the real tensile study;
- inspect figures and tables;
- record what the data support and what remains uncertain.

Each phase should be limited, tested, documented, and reviewed before the next phase begins.

## Explicit exclusions

Do not add in this effort:

- OCE or OCT concepts;
- Lamb-wave or other wave propagation models;
- acoustoelasticity or small-on-large theory;
- incremental elasticity tensors or directional moduli;
- dispersion inversion;
- viscoelastic models;
- new constitutive models without evidence;
- a separate fit for every deformation state;
- duplicated tension or joint workflows;
- compatibility wrappers or obsolete aliases.

## Validation protocol

For every phase:

1. run focused behavioral tests;
2. run `run_all_tests()`;
3. inspect generated artifacts when outputs exist;
4. use synthetic recovery before interpreting real fits;
5. preserve the completed tensile study as the canonical source;
6. record unavailable or inconclusive validation explicitly;
7. do not merge unless explicitly requested.
