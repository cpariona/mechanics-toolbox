# Compression study

Compression uses the shared uniaxial mechanics pipeline after test-specific selection of the maintained cycle and loading branch. Conditioning cycles are excluded from the analyzed response.

## Workflow hierarchy

- `compressionConfig`: preprocessing and mechanics for one processed curve;
- `compressionSpecimenConfig`: import, cycle selection, geometry, fitting, export, and reporting for one specimen;
- `compressionStudyConfig`: several specimens, population analysis, and the study bundle;
- `compressionStudyComparisonConfig`: comparison of completed studies;
- `compressionStudyReportConfig`: report presentation;
- `studies/compression/run_compression_experiment.m`: maintained real-experiment driver.

## One specimen

```matlab
config = mechanics.config.compressionSpecimenConfig();
config.geometry.initialLength = 25;
config.geometry.initialArea = 100;
config.cycle.selection = "last-complete-cycle";
config.cycle.branch = "loading";

result = mechanics.workflow.runCompressionSpecimen( ...
    "compression.csv", config);
```

When export is enabled, `runCompressionSpecimen` delegates to `mechanics.io.exportCompressionSpecimen`. The bundle contains the processed table, cycle metrics, `compression_specimen.mat`, and the configured report.

## One study

```matlab
config = mechanics.config.compressionStudyConfig();
config.input.type = "workbook";
config.extraction.extractor = "auto";
config.export.enabled = true;
config.export.outputFolder = "results/compression-study";

study = mechanics.workflow.runCompressionStudy( ...
    "data/raw/compression.xlsx", config);
```

The workflow also accepts a pre-extracted dataset, workbook list, or manifest. The normalized manifest contains `File`, `SpecimenId`, `InitialLength`, `InitialArea`, `Include`, and `Sheet`.

For circular specimens, the Zwick adapter recognizes `d0` and `h0` and resolves:

```text
initialArea = pi*d0^2/4
initialLength = h0
```

## Study bundle

`runCompressionStudy` delegates study-level persistence to `mechanics.io.exportCompressionStudy` and records paths under `study.outputFiles`.

The default bundle contains:

```text
compression_study.mat
compression_manifest.csv
compression_summary.csv
population_curve.csv
population_metrics.csv
population_tangent_modulus.csv
selected_model_parameter_values.csv
selected_model_parameter_summary.csv
```

`compression_study.mat` contains the complete `study`, including `study.config` and `study.population`. No separate configuration MAT or population MAT is generated inside the study bundle.

Population tables are produced by the shared `mechanics.io.exportPopulationAnalysis` implementation. Its autonomous use still writes `population_analysis.mat` by default; integrated study exporters disable that duplicate MAT.

## ASTM D575 Method A convention

The maintained real workflow expects three successive cycles, uses the first two for conditioning, selects the last complete cycle, analyzes its loading branch, and applies first-sample zeroing without a preload threshold.

Exclusions remain explicit:

```matlab
config.specimens.excludeIndices = [1; 2];
config.specimens.exclusionReason = ...
    "Initial thickness outside ASTM D575 tolerance";
```

Excluded rows remain in `study.manifest` and `study.analysis.summary`; population analysis uses only processed records.

## Shared and compression-specific behavior

Tension and compression share stress-strain processing, tangent-modulus estimation, constitutive fitting, uncertainty propagation, population aggregation, selected-parameter analysis, group comparison, unit formatting, and PNG/FIG persistence.

Compression retains cycle selection, loading/unloading interpretation, contact-oriented preprocessing, hysteresis, and cycle diagnostics. Stored displacement, strain, and stress use physical negative compression signs; reports may display positive magnitudes without modifying the stored state.

## Integrated report

```matlab
reportConfig = mechanics.config.compressionStudyReportConfig();
reportConfig.outputFolder = "results/compression-study/report";
reportFiles = mechanics.io.exportCompressionStudyReport( ...
    study, reportConfig);
```

Each maintained report figure is written as both the configured image format and an editable MATLAB `.fig`.

## Comparing completed studies

```matlab
comparison = mechanics.workflow.compareCompressionStudies( ...
    [studyA, studyB], ...
    ["Condition A", "Condition B"], ...
    mechanics.config.compressionStudyComparisonConfig());
```

The comparison validates measures and units and reuses the common population and group-comparison workflows without re-importing or refitting data.

## Validation

Real compression datasets require visual confirmation of cycle selection, zeroing, sign normalization, fitting range, area assumptions, and explicit protocol exclusions. For the current experiment, a crosshead speed of `20 mm/min` should be reported as a protocol deviation when strict ASTM D575 Method A compliance is claimed.
