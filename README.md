# mechanics-toolbox

MATLAB toolbox for reproducible processing, constitutive fitting, statistical analysis, and peak/post-peak characterization of uniaxial mechanical-test data.

## Maintained scope

- workbook and delimited-file import;
- vendor-specific Zwick extraction for tensile and compression workbooks;
- preservation of raw experimental data;
- preprocessing and stress-strain conversion;
- tangent-modulus estimation;
- Neo-Hookean, Mooney-Rivlin, and Yeoh constitutive models;
- bounded nonlinear parameter fitting and diagnostics;
- reliability-aware model comparison and selection;
- dataset quality assessment and tensile loading segmentation;
- peak, post-peak, and energy descriptors without rupture classification;
- replicate population statistics and bootstrap intervals;
- group comparison and selected-parameter inference;
- tensile and compression study workflows;
- joint tension-compression material characterization;
- tensile application-range characterization with parsimonious shared-model selection;
- fit-range sensitivity and fixed-parameter external compression validation;
- measurement-aware Monte Carlo refitting;
- end-to-end execution, figures, and reporting.

## Repository layout

```text
src/+mechanics/   Maintained package implementation
studies/          Executable configurations for real experiments
examples/         Runnable API demonstrations
tests/            Automated regression tests
docs/             User, reference, and development documentation
startup.m         Adds maintained folders to the MATLAB path
run_all_tests.m   Runs the complete repository test suite
```

Root-level processing functions are not maintained. Public code should use the package API under `src/+mechanics`.

Local experimental workbooks belong under `data/raw/` and generated outputs under `results/`. Both locations are ignored by Git and must not be committed.

## Setup and validation

```matlab
startup
results = run_all_tests();
```

See [`docs/development/testing.md`](docs/development/testing.md) for focused test execution and release validation.

## Tensile studies

```matlab
config = mechanics.config.tensileStudyConfig();
config.extraction.defaultInitialLength = 25;
config.datasetAnalysis.fitting.enabled = true;
config.export.enabled = true;
config.export.outputFolder = "results/my-study";

study = mechanics.workflow.runTensileStudy( ...
    "data/raw/test.xlsx", config);
```

Maintained experiment driver:

```text
studies/tension/run_tensile_experiment.m
```

Compare completed studies without reprocessing specimens:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    [studyA, studyB], ["Condition A", "Condition B"]);
```

## Compression studies

```matlab
config = mechanics.config.compressionStudyConfig();
config.specimens.excludeIndices = [1; 2];
config.specimens.exclusionReason = ...
    "Initial thickness outside ASTM D575 tolerance";

study = mechanics.workflow.runCompressionStudy( ...
    "data/raw/compression.xlsx", config);
```

Maintained experiment driver:

```text
studies/compression/run_compression_experiment.m
```

The maintained ASTM D575 Method A configuration selects the final complete cycle and analyzes its loading branch. Dimensional compliance and experimental exclusions remain explicit user decisions.

Compare completed studies with:

```matlab
comparison = mechanics.workflow.compareCompressionStudies( ...
    [studyA, studyB], ["Condition A", "Condition B"]);
```

## Tensile application-range characterization

Consume a completed tensile study and optionally validate the tensile-calibrated model against a completed compression study without refitting:

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config, compressionStudy);
```

The workflow performs shared candidate fitting, parsimonious selection, registry-derived reference-property evaluation, range-sensitivity auditing, unit-aware export, and optional external compression prediction.

Maintained real-study driver:

```text
studies/tension/run_tensile_application_range_characterization.m
```

## Joint material characterization

Joint characterization consumes completed tensile and compression studies through one explicit workflow and does not re-import raw workbooks or rerun the individual study pipelines.

```matlab
config = mechanics.config.jointMaterialCharacterizationConfig();
result = mechanics.workflow.runJointMaterialCharacterization( ...
    tensileStudy, compressionStudy, config);
```

## Shared uniaxial architecture

Tension and compression share import normalization, mechanical measures, tangent modulus, constitutive fitting, uncertainty, population analysis, group comparison, unit-aware labels, and maintained figure export when their contracts are identical.

Test-specific behavior remains separate:

- tension: loading segmentation and peak/post-peak interpretation;
- compression: cycle selection, loading/unloading branches, hysteresis, and cycle diagnostics.

Stored mechanics use physical signs. Compression reports may display positive magnitudes without changing the stored state.

## Reporting and figure export

Maintained reports are exposed through `mechanics.io`, including tensile, compression, constitutive, joint-characterization, and tensile application-range reports.

Every maintained workflow figure is persisted through `mechanics.plotting.exportFigureFiles` as:

```text
figure_name.png   % or configured image format
figure_name.fig   % editable MATLAB figure
```

Manual figures created directly in study drivers are not required to follow this persistence contract.

## Constitutive models

Registered models:

- `neo-hookean`;
- `mooney-rivlin`;
- `yeoh-second-order`;
- `yeoh-third-order`.

The two Yeoh variants share the single evaluator `mechanics.models.yeoh` and registry family name `yeoh`. The bare identifier `yeoh` is not a registered model or compatibility alias.

Model functions only evaluate constitutive equations. They do not read files, modify experimental data, plot, or invoke optimizers.

## Documentation

Start at [`docs/README.md`](docs/README.md). Current persistent project state and maintenance priorities are recorded only in [`docs/development/context-handoff.md`](docs/development/context-handoff.md).
