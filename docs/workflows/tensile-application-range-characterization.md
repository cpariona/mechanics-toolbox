# Tensile application-range characterization

## Status

D1 input and range contracts are implemented on the feature branch. Shared fitting, model selection, range sensitivity, optional compression validation, plotting, export, and the real-study driver remain unimplemented.

The capability is a maintained add-on to a completed tensile study:

```text
runTensileStudy
    -> completed tensile study
    -> runTensileApplicationRangeCharacterization
```

It must not re-import workbooks, repeat tensile preprocessing, or become a second tensile-study workflow.

## Purpose

The completed workflow will answer one limited constitutive question:

> Which supported hyperelastic model and shared reference parameter set best describe the processed tensile loading responses inside a configured application range?

The initial real use case is an engineering-strain interval such as `[0, 0.30]`. The implementation remains independent of OCE, OCT, Lamb waves, acoustoelasticity, incremental elasticity, wave inversion, and dispersion modelling.

## D1 maintained configuration

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.deformationMeasure = "engineering-strain";
config.fitRange = [0, 0.30];
config.minimumObservationsPerSpecimen = 10;
config.minimumSpecimens = 2;
config.requireRangeMaximum = false;
config.candidateModelNames = ["neo-hookean"; "mooney-rivlin"; "yeoh"];
```

A two-element vector represents every closed interval. Separate `minimum` and `maximum` fields are intentionally not used.

D1 also provides finite-observation, matching-unit, and scale-aware sign-validation settings. Fitting, selection, audit, validation, and export configuration are not exposed until a maintained consumer exists.

## D1 maintained normalizer

```matlab
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    tensileStudy, config);
```

The input must be one completed tensile-study result containing processed specimen records. Population analysis and individual constitutive fitting are not prerequisites.

The normalizer:

- ignores records not marked `processed`;
- reads the already processed strain, stress, units, and mechanics metadata;
- maps stored engineering and true measures to the maintained constitutive context;
- validates tensile signs with the same scale-aware principle used by joint characterization;
- validates registered candidate model names through `mechanics.models.modelRegistry`;
- restricts observations using the configured closed interval;
- preserves complete source vectors and original observation indices;
- records available, requested, and actually fitted ranges;
- records retained and excluded observation counts;
- records excluded specimens and explicit exclusion reasons;
- rejects the analysis when too few valid specimens remain;
- never clips, zeroes, interpolates, rescales, extrapolates, or mutates source observations.

The requested boundary is not required to coincide with an experimental sample. `FittedRange` reports the actual first and last retained observations.

## Normalized result contract

```matlab
normalized.sourceStudyMetadata
normalized.deformationMeasure
normalized.requestedFitRange
normalized.specimens
normalized.excludedSpecimens
normalized.specimenCount
normalized.excludedSpecimenCount
normalized.observationCount
normalized.specimenSummary
normalized.exclusionSummary
normalized.config
normalized.createdAt
```

Each retained specimen contains:

```text
SourceRecordIndex
SourceSpecimenId
SourceSheetName
FullDeformation
FullMeasuredStress
IncludedIndices
ExcludedIndices
Deformation
MeasuredStress
AvailableRange
RequestedFitRange
FittedRange
Context
StrainUnit
StressUnit
ObservationCount
ExcludedObservationCount
```

## Reuse decisions

D1 directly reuses the model registry for candidate validation and preserves the same mechanics metadata, unit, finite-observation, and scale-aware sign concepts used in existing maintained workflows.

`normalizeJointCharacterizationStudies` is not reused because its public contract requires modes, mode weights, and multi-mode normalization. Coupling this tensile add-on to those fields would add unnecessary structure and obscure the single-mode contract.

No shared helper was extracted in D1. A lower-level function should be extracted only when at least two maintained callers use the same physical and data contract.

## D1 validation

Behavioral coverage is maintained in:

```text
tests/test_tensile_application_range_input_contract.m
```

The focused test and the complete `run_all_tests()` suite were reported passing after correction of summary-table orientation and sampling-grid-independent boundary assertions.

Covered behavior includes:

- source-study immutability;
- range configurability;
- inclusive interval filtering;
- preservation of source indices and curves;
- independence from population and individual fitting outputs;
- ignored failed records;
- insufficient-observation and insufficient-specimen handling;
- optional requirement that the requested maximum be available;
- unit, measure, finite-value, sign, and model-registry validation.

## Planned public workflow

D2 and later phases will introduce the public entrypoint:

```matlab
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);
```

Do not add this entrypoint as an empty wrapper before fitting exists.

## D2 — Range-limited shared fitting

D2 should:

- consume the D1 normalized contract;
- fit one shared parameter vector per candidate model;
- give each specimen equal influence regardless of sampling density;
- reuse model evaluation, bounds, parameter transforms, multistart, and diagnostics where contracts match;
- retain per-specimen predictions and physical fit metrics;
- validate synthetic recovery and sampling-density invariance.

Do not call the joint fitter directly if doing so requires artificial mode fields or weights. Extract a solver-only lower-level function only when its contract is genuinely shared by at least two maintained callers.

## D3 — Selection and reference properties

D3 should:

- reject failed or nonfinite candidates;
- apply reliability and identifiability evidence where maintained;
- treat materially negligible objective differences as practical equivalence;
- prefer fewer parameters among practically equivalent candidates;
- use configured order only as the final deterministic tie-break;
- derive reference quantities through the model registry rather than workflow conditionals.

For currently supported incompressible models, the intended reference quantity is:

```text
Neo-Hookean:   mu0 = mu
Mooney-Rivlin: mu0 = 2 * (C10 + C01)
Yeoh:          mu0 = 2 * C10
```

The Neo-Hookean registry metadata must be made consistent before D3 exposes `mu0` generically.

## D4 — Range sensitivity and optional validation

D4 should vary only the upper application-range boundary initially. Each scenario must reuse the same normalization, fitting, and selection contract.

Compression may be supplied only for prediction with the tensile-selected model and fixed parameters. It must not affect tensile fitting or selection and must not trigger refitting.

## D5 — Driver, output, and real validation

Planned driver:

```text
studies/tension/run_tensile_application_range_characterization.m
```

Primary local input:

```text
results/real-tensile-study/tensile_study.mat
```

Optional validation input:

```text
results/real-compression-study/compression_study.mat
```

Generated files remain under ignored `results/` paths.

## Explicit exclusions

Do not add in this effort:

- raw workbook import or repeated tensile preprocessing;
- OCE or OCT concepts;
- wave propagation, Lamb waves, dispersion inversion, or acoustoelasticity;
- incremental elasticity tensors or directional moduli;
- viscoelastic models;
- a separate model fit for every deformation state;
- new constitutive models without evidence;
- compatibility wrappers, aliases, bridge files, or one-caller helpers.

## Validation gate

For every phase:

1. run focused behavioral tests;
2. run `run_all_tests()`;
3. inspect generated artifacts when outputs exist;
4. use synthetic recovery before interpreting real fits;
5. run `git diff --check` and verify no generated files are tracked;
6. do not merge unless explicitly requested.
