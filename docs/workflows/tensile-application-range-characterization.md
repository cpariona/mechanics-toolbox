# Tensile application-range characterization

## Status

D1 input/range contracts, D2 shared fitting, D3 parsimonious selection, and D4 range sensitivity with optional fixed-parameter compression validation are implemented on the active feature branch.

Plotting, export, the public orchestration entrypoint, the real-study driver, and real-data validation remain for D5.

This capability is a maintained add-on to a completed tensile study:

```text
runTensileStudy
    -> completed tensile study
    -> normalizeTensileApplicationRangeStudy
    -> fitTensileApplicationRangeModels
    -> selectTensileApplicationRangeModel
    -> optional range-sensitivity audit
    -> optional fixed-parameter compression validation
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
config.rangeSensitivity.maximumDeformations = [0.20; 0.25; 0.30];
config.compressionValidation.minimumSpecimens = 1;
```

A two-element vector represents each closed fitting interval. Sensitivity maxima are stored as one ordered numeric vector.

## D1-D3 maintained pipeline

```matlab
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    tensileStudy, config);

candidates = mechanics.workflow.fitTensileApplicationRangeModels( ...
    normalized, config);

selection = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);
```

D1 restricts existing processed tensile observations without mutating source data. D2 estimates one shared parameter vector per candidate model, using equal influence per specimen. D3 rejects ineligible candidates, applies practical equivalence, prefers fewer parameters, and derives reference quantities through `modelRegistry`.

Registry-derived reference properties are:

```text
Neo-Hookean:   mu0 = mu
Mooney-Rivlin: mu0 = 2 * (C10 + C01)
Yeoh:          mu0 = 2 * C10
```

## D4 range-sensitivity audit

```matlab
audit = mechanics.workflow.auditTensileApplicationRangeSensitivity( ...
    tensileStudy, config);
```

For each configured upper deformation limit, D4 reuses the full D1-D3 contract with only `scenarioConfig.fitRange(2)` changed.

Each scenario records:

```text
maximumDeformation
status
normalized
candidates
selection
errorIdentifier
errorMessage
```

The summary table records:

```text
MaximumDeformation
Status
SelectedModelName
Objective
Mu0
```

Scenario order follows `config.rangeSensitivity.maximumDeformations`. Invalid or repeated maxima are rejected. A failed scenario is recorded independently and does not erase other scenario evidence.

## D4 optional compression validation

```matlab
validation = mechanics.workflow.validateTensileApplicationRangeCompression( ...
    selection, compressionStudy, config);
```

Compression is external validation only. The selected tensile model and fitted parameter vector are held fixed.

The implementation reuses the maintained compression mode contract through:

```matlab
mechanics.workflow.normalizeJointCharacterizationStudies
```

with one `compression` mode. This preserves existing validation of signs, units, measures, finite observations, and completed-study structure.

Predictions are evaluated with:

```matlab
mechanics.models.evaluateModel( ...
    selection.selectedModelName, ...
    compressionDeformation, ...
    selection.selectedFit.parameters, ...
    compressionContext)
```

The result declares:

```matlab
validation.refitPerformed = false;
```

Compression data cannot influence tensile normalization, fitting, candidate eligibility, or selection.

The validation result includes:

```text
modelName
parameters
refitPerformed
normalizedCompression
specimens
specimenSummary
meanRMSE
meanNormalizedRMSE
config
createdAt
```

Each compression specimen retains predictions, residuals, and its normalization scale.

## Reuse decisions

D4 reuses D1 normalization, D2 candidate fitting, and D3 selection directly for every sensitivity scenario. It does not introduce a parallel fitting or ranking implementation.

Compression validation reuses the existing joint-mode normalizer because its single-mode compression contract is physically identical to the required external-validation input contract. It does not call joint fitting or joint selection.

No compatibility wrapper, bridge file, alias layer, or one-caller helper was added.

## Validation evidence

The user reported successful execution of:

```text
tests/test_tensile_application_range_input_contract.m
tests/test_tensile_application_range_fitting.m
tests/test_tensile_application_range_selection.m
tests/test_tensile_application_range_audit.m
run_all_tests()
```

D4 behavioral coverage includes:

- execution of every configured upper-range scenario;
- source tensile-study immutability;
- stable synthetic model and `mu0` recovery across scenarios;
- rejection of invalid or repeated sensitivity maxima;
- fixed-parameter compression prediction;
- explicit evidence that no compression refitting occurred;
- near-exact synthetic compression recovery;
- minimum compression-specimen enforcement.

Do not claim additional MATLAB validation beyond this user-reported evidence.

## D5 — Public workflow, outputs, and real validation

D5 should add the maintained public orchestration entrypoint:

```matlab
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);
```

Planned real driver:

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

D5 should add only nonredundant plotting/export outputs and perform real-data validation. Generated files remain under ignored `results/` paths.

## Explicit exclusions

Do not add:

- raw workbook import or repeated tensile preprocessing;
- compression refitting or compression influence on tensile selection;
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
