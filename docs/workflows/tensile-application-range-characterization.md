# Tensile application-range characterization

## Status

D1 input/range contracts and D2 shared fitting are implemented on the active feature branch. Model selection, registry-derived reference properties, range sensitivity, optional compression validation, plotting, export, and the real-study driver remain unimplemented.

This capability is a maintained add-on to a completed tensile study:

```text
runTensileStudy
    -> completed tensile study
    -> runTensileApplicationRangeCharacterization
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
```

A two-element vector represents every closed interval. Separate minimum and maximum fields are not used.

## D1 normalized input contract

```matlab
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    tensileStudy, config);
```

The normalizer consumes one completed tensile-study result and:

- uses processed specimen records only;
- does not require population analysis or individual fitting outputs;
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

The objective is the arithmetic mean of the normalized specimen losses:

```text
candidate objective
    = mean(normalized loss of each retained specimen)
```

This contract gives each specimen equal influence regardless of sampling density. A pooled pointwise SSE is not used.

The maintained normalization is `response-range` per specimen. The response range is used when valid; otherwise the implementation falls back to the maximum absolute response and applies `normalization.minimumScale`.

Each successful fit preserves:

```text
modelName
parameterNames
parameters
objective
exitFlag
output
converged
specimenWeighting
specimens
specimenSummary
normalization
fitConfig
starts
createdAt
```

Each fitted specimen adds:

```text
PredictedStress
Residuals
NormalizationScale
```

Candidate fitting records failures independently so one failed model does not discard successful candidates. Selection is not performed in D2.

## Reuse decisions

D2 directly reuses:

```text
mechanics.models.modelRegistry
mechanics.models.evaluateModel
mechanics.fitting.resolveFitConfig
mechanics.fitting.generateInitialGuesses
mechanics.fitting.parametersToUnconstrained
mechanics.fitting.unconstrainedToParameters
```

`fitJointModel` is not called as a wrapper because its maintained contract includes modes, mode weights, and multi-mode summaries.

No generic multistart helper was extracted in D2. That refactor should occur only when at least two maintained callers are proven to share the same solver-only contract and the change can be covered without destabilizing validated fitting behavior.

## Validation evidence

The user reported successful execution of:

```text
tests/test_tensile_application_range_input_contract.m
tests/test_tensile_application_range_fitting.m
run_all_tests()
```

D2 behavioral coverage includes:

- synthetic Neo-Hookean recovery;
- synthetic Yeoh recovery;
- one shared parameter vector across specimens;
- retained predictions and physical residuals;
- invariance to duplicated sampling points in one specimen;
- one result record per configured candidate;
- rejection of unsupported specimen weighting;
- rejection of unsupported normalization.

## Planned public workflow

The final public orchestration entrypoint remains deferred until selection exists:

```matlab
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);
```

Do not add an empty orchestration wrapper.

## D3 — Selection and reference properties

D3 should:

- reject failed or nonfinite candidates;
- apply maintained convergence and reliability evidence;
- treat materially negligible objective differences as practical equivalence;
- prefer fewer parameters among practically equivalent candidates;
- use configured order only as the final deterministic tie-break;
- derive reference quantities through the model registry rather than workflow conditionals.

Intended reference quantity:

```text
Neo-Hookean:   mu0 = mu
Mooney-Rivlin: mu0 = 2 * (C10 + C01)
Yeoh:          mu0 = 2 * C10
```

Neo-Hookean registry metadata must expose `mu0 = mu` before D3 reports derived quantities generically.

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
