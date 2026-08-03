# Tensile application-range characterization

## Status

D1 input/range contracts, D2 shared fitting, and D3 parsimonious selection with registry-derived reference properties are implemented on the active feature branch.

Range sensitivity, optional compression validation, plotting, export, the public orchestration entrypoint, and the real-study driver remain unimplemented.

This capability is a maintained add-on to a completed tensile study:

```text
runTensileStudy
    -> completed tensile study
    -> normalizeTensileApplicationRangeStudy
    -> fitTensileApplicationRangeModels
    -> selectTensileApplicationRangeModel
```

It must not re-import workbooks or repeat tensile preprocessing.

## Maintained configuration

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.deformationMeasure = "engineering-strain";
config.fitRange = [0, 0.30];
config.minimumObservationsPerSpecimen = 10;
config.minimumSpecimens = 2;
config.requireRangeMaximum = false;
config.candidateModelNames = ["neo-hookean"; "mooney-rivlin"; "yeoh"];
config.specimenWeighting = "equal";
config.normalization.method = "response-range";
config.normalization.minimumScale = sqrt(eps);
config.fitting = mechanics.config.fittingConfig();
config.selection.requireConvergence = true;
config.selection.practicalObjectiveTolerance = 0.02;
config.selection.tieBreakOrder = config.candidateModelNames;
```

A two-element vector represents every closed interval. Separate minimum and maximum fields are not used.

## D1 normalized input contract

```matlab
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    tensileStudy, config);
```

The normalizer consumes one completed tensile-study result and:

- uses processed specimen records only;
- validates finite observations, tensile signs, units, measures, and registered candidates;
- restricts observations to the configured interval without changing source data;
- preserves full curves and original observation indices;
- records available, requested, and actual fitted ranges;
- records specimen exclusions and observation counts;
- rejects the analysis when too few valid specimens remain.

The requested boundary need not coincide with a sampled observation. `FittedRange` records the actual retained endpoints.

## D2 shared fitting contract

Fit one registered model:

```matlab
fit = mechanics.fitting.fitTensileApplicationRangeModel( ...
    normalized, modelName, config);
```

Fit every configured candidate:

```matlab
candidates = mechanics.workflow.fitTensileApplicationRangeModels( ...
    normalized, config);
```

For each candidate model, D2 estimates one parameter vector shared by every retained tensile specimen.

The objective is the arithmetic mean of the normalized specimen losses. Each specimen therefore has equal influence regardless of sampling density. A pooled pointwise SSE is not used.

The maintained normalization is `response-range` per specimen. Each successful fit preserves model metadata, parameters, objective, multistart diagnostics, convergence state, per-specimen predictions, residuals, normalization scales, and physical error summaries.

Candidate failures are recorded independently so one failed model does not discard successful candidates.

## D3 selection contract

```matlab
selection = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);
```

The selector consumes the completed D2 candidate records and does not refit any model.

Selection order:

1. reject failed candidates;
2. reject nonfinite objectives;
3. reject nonconverged candidates when `selection.requireConvergence` is true;
4. identify the lowest eligible objective;
5. define practical equivalence using `selection.practicalObjectiveTolerance`;
6. prefer fewer parameters among practically equivalent candidates;
7. use objective and then configured order as deterministic tie-breaks.

Candidate names and tie-break names are canonicalized through `mechanics.models.modelRegistry`. Aliases of the same registered model cannot be supplied as distinct candidates.

The result preserves:

```text
candidates
candidateSummary
selectedModelName
selectedFit
referenceProperties
selection
config
createdAt
```

The candidate summary records status, convergence, eligibility, practical equivalence, parameter count, objective, and configured order.

## Registry-derived reference properties

Reference properties are evaluated through model metadata rather than workflow model-name conditionals:

```text
Neo-Hookean:   mu0 = mu
Mooney-Rivlin: mu0 = 2 * (C10 + C01)
Yeoh:          mu0 = 2 * C10
```

The generic result contains:

```text
referenceProperties.modelName
referenceProperties.names
referenceProperties.values
referenceProperties.parameterNames
referenceProperties.parameters
```

Neo-Hookean now exposes `mu0` consistently through `modelRegistry`.

## Reuse decisions

D2 directly reuses maintained model evaluation, fitting configuration, bounds, multistart generation, and parameter transforms.

D3 follows the same practical-equivalence and parsimonious ranking policy used by joint characterization, but it operates on already fitted tensile candidates. It does not call `selectJointModel`, because that function owns joint fitting, mode summaries, and multi-mode responsibilities.

No compatibility wrapper, alias layer, bridge file, or one-caller helper was added.

## Validation evidence

The user reported successful execution of:

```text
tests/test_tensile_application_range_input_contract.m
tests/test_tensile_application_range_fitting.m
tests/test_tensile_application_range_selection.m
run_all_tests()
```

D3 behavioral coverage includes:

- best-objective selection outside practical equivalence;
- preference for the simpler model inside practical equivalence;
- failed and nonconverged candidate exclusion;
- optional disabling of the convergence requirement;
- rejection when no eligible candidate exists;
- tie-break order validation;
- canonical duplicate-alias rejection;
- generic `mu0` evaluation for Neo-Hookean, Mooney-Rivlin, and Yeoh.

## Planned public workflow

The final public orchestration entrypoint remains deferred until D4 or D5 can return the complete maintained result:

```matlab
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);
```

Do not add an empty orchestration wrapper.

## D4 — Range sensitivity and optional validation

D4 should initially vary only the upper application-range boundary and reuse the same normalization, fitting, and selection contracts.

Compression may be supplied only for prediction using the fixed tensile-selected model and parameters. It must not influence tensile fitting or selection and must not trigger refitting.

## D5 — Driver, outputs, and real validation

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

Do not add:

- raw workbook import or repeated tensile preprocessing;
- OCE, OCT, wave propagation, Lamb waves, dispersion inversion, or acoustoelasticity;
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
