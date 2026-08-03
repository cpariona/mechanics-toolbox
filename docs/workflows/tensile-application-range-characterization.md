# Tensile application-range characterization

## Status

D1-D5 are implemented on the active feature branch. The maintained capability now includes input/range normalization, shared candidate fitting, parsimonious selection, range-sensitivity auditing, optional fixed-parameter compression validation, a public orchestration entrypoint, nonredundant export, and a real-study driver.

The remaining work is experimental validation with the maintained real studies and any evidence-driven visualization refinements.

## Public workflow

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);
```

Optional compression validation:

```matlab
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config, compressionStudy);
```

The workflow composes the maintained contracts without duplicating their logic:

```text
completed tensile study
    -> normalizeTensileApplicationRangeStudy
    -> fitTensileApplicationRangeModels
    -> selectTensileApplicationRangeModel
    -> auditTensileApplicationRangeSensitivity
    -> optional validateTensileApplicationRangeCompression
    -> optional exportTensileApplicationRangeCharacterization
```

It does not re-import raw workbooks or repeat tensile preprocessing.

## Maintained configuration

```matlab
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
config.export.enabled = false;
config.export.outputFolder = ...
    "results/tensile-application-range-characterization";
```

Closed fitting intervals use one two-element vector. Sensitivity maxima use one ordered numeric vector.

## Result contract

The public result includes:

```text
normalized
candidates
candidateSummary
selectedModelName
selectedFit
referenceProperties
selection
rangeSensitivity
compressionValidation
hasCompressionValidation
config
createdAt
outputFiles
```

The selected reference quantity is evaluated through `modelRegistry`:

```text
Neo-Hookean:   mu0 = mu
Mooney-Rivlin: mu0 = 2 * (C10 + C01)
Yeoh:          mu0 = 2 * C10
```

## Range sensitivity

Each configured upper range limit reruns the maintained D1-D3 pipeline while changing only:

```matlab
scenarioConfig.fitRange(2)
```

The audit preserves complete scenario evidence and exposes a summary with:

```text
MaximumDeformation
Status
SelectedModelName
Objective
Mu0
```

Failed scenarios are retained independently.

## Compression validation

Compression is external validation only. The tensile-selected model and parameters remain fixed.

The implementation reuses the maintained compression normalization contract and evaluates predictions through `mechanics.models.evaluateModel`.

The result explicitly records:

```matlab
validation.refitPerformed = false;
```

Compression cannot influence tensile normalization, fitting, candidate eligibility, or selection.

## Export

When `config.export.enabled` is true, the maintained exporter writes:

```text
candidate_model_summary.csv
selected_parameters.csv
reference_properties.csv
tensile_specimen_fit_summary.csv
range_sensitivity_summary.csv
compression_validation_summary.csv   % only when compression is supplied
tensile_application_range_characterization.mat
tensile_application_range_characterization.md
```

Complete observations, predictions, residuals, candidates, and scenario evidence remain in the MAT result. Curves are not duplicated into additional CSV files.

No new figures are generated in D5. Plotting should be added only after real-result inspection demonstrates a nonredundant scientific need.

## Real-study driver

```text
studies/tension/run_tensile_application_range_characterization.m
```

Primary input:

```text
results/real-tensile-study/tensile_study.mat
```

Optional validation input:

```text
results/real-compression-study/compression_study.mat
```

Generated files remain under ignored `results/` paths.

## Validation evidence

The user reported successful execution of:

```text
tests/test_tensile_application_range_input_contract.m
tests/test_tensile_application_range_fitting.m
tests/test_tensile_application_range_selection.m
tests/test_tensile_application_range_audit.m
tests/test_tensile_application_range_workflow.m
run_all_tests()
```

The D5 validation also confirmed that the default export configuration is present, disabled, and points to the maintained output folder.

Do not claim real-data validation until the driver has been executed and its generated outputs have been inspected.

## Remaining work

The required algorithmic workflow is complete. Remaining work is:

1. execute the real-study driver;
2. inspect selected model, parameters, `mu0`, specimen errors, sensitivity, and optional compression prediction;
3. inspect exported CSV, MAT, and Markdown artifacts;
4. add plotting only if the real outputs reveal a specific nonredundant need;
5. document scientific interpretation and limitations from the real analysis.

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

1. run focused behavioral tests;
2. run `run_all_tests()`;
3. run `git diff --check`;
4. verify no generated files are tracked;
5. inspect real generated artifacts before interpreting results;
6. do not merge unless explicitly requested.
