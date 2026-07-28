# Compression study

Compression data use the shared uniaxial mechanics pipeline after test-specific selection of the maintained measurement cycle and loading branch. Conditioning cycles are excluded from the analyzed response.

## Workflow hierarchy

- `compressionConfig` controls preprocessing and mechanics for one processed curve;
- `compressionSpecimenConfig` controls import, cycle selection, geometry, fitting, export, and reporting for one specimen;
- `compressionStudyConfig` coordinates several specimens, population analysis, and the maintained study bundle;
- `compressionStudyComparisonConfig` controls comparison of completed studies;
- `compressionStudyReportConfig` controls individual and population report presentation;
- `studies/compression/run_compression_experiment.m` is the maintained human-facing driver for one real experiment.

Experiment-specific paths, exclusions, and optional analyses remain in the driver. Reusable extraction, mechanics, statistics, plotting, export, and report generation remain under `src/+mechanics`.

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

Only the selected branch is passed to stress-strain conversion, tangent-modulus estimation, constitutive fitting, and measurement Monte Carlo.

When `config.export.enabled` is true, `runCompressionSpecimen` delegates to `mechanics.io.exportCompressionSpecimen`. The maintained specimen bundle contains the processed table, cycle metrics, `compression_specimen.mat`, and the configured single-specimen report. The name `exportCompressionStudy` is reserved for multi-specimen study results.

## One study

A Zwick workbook may be passed directly to the study workflow:

```matlab
config = mechanics.config.compressionStudyConfig();
config.input.type = "workbook";
config.extraction.extractor = "auto";
config.export.enabled = true;
config.export.outputFolder = "results/compression-study";

study = mechanics.workflow.runCompressionStudy( ...
    "data/raw/compression.xlsx", config);
```

The same workflow accepts a pre-extracted dataset, a workbook list, or a manifest. Manifest input requires `File`, `SpecimenId`, and `InitialArea`; `InitialLength`, `Include`, and `Sheet` are optional.

The shared Zwick adapter reads specimen sheets and the `Resultados` sheet. For circular compression specimens, it recognizes `d0` and `h0` and resolves:

```text
initialArea = pi*d0^2/4
initialLength = h0
```

The normalized manifest contains `File`, `SpecimenId`, `InitialLength`, `InitialArea`, `Include`, and `Sheet`.

## Study bundle

`runCompressionStudy` owns study-level export. When enabled, it calls `mechanics.io.exportCompressionStudy` and records the returned paths under `study.outputFiles`.

The default bundle contains all relevant nonredundant study outputs:

```text
compression_study.mat
compression_manifest.csv
compression_summary.csv
population_analysis.mat
population_curve.csv
population_metrics.csv
population_tangent_modulus.csv
selected_model_parameter_values.csv
selected_model_parameter_summary.csv
```

Population files are generated only when population analysis completes. They are produced by the shared `mechanics.io.exportPopulationAnalysis` implementation and are exposed under `study.outputFiles.population`.

The MAT file contains `study`, including `study.config`; no separate compression configuration MAT file is generated.

## ASTM D575 Method A convention

The maintained real-experiment workflow follows this cycle structure:

- three successive compression cycles are expected;
- the first two cycles condition the specimen;
- the last complete cycle is selected;
- the loading branch of that cycle is analyzed;
- the first selected observation defines the mechanical zero;
- no preload threshold is applied.

Standard compliance and experimental suitability are not inferred by the extractor. Exclusions are explicit and follow workbook extraction order:

```matlab
config.specimens.excludeIndices = [1; 2];
config.specimens.exclusionReason = ...
    "Initial thickness outside ASTM D575 tolerance";
```

Excluded rows remain visible in `study.manifest` and `study.analysis.summary` with `Include=false` and `Status="skipped"`. Population analysis uses only processed records.

## Study result

The result contains:

```text
study.input
study.manifest
study.exclusion
study.analysis
study.population
study.populationStatus
study.sourceFiles
study.config
study.outputFiles       % when export is enabled
```

The manifest describes ingestion and inclusion only. Experimental group labels are assigned downstream and are not inferred from it.

## Shared and test-specific behavior

Compression and tension share maintained implementations for stress-strain processing, tangent-modulus estimation, constitutive fitting, uncertainty propagation, population aggregation, selected-parameter analysis, group comparison, unit formatting, and PNG/FIG persistence.

Compression retains its own cycle selection, loading/unloading interpretation, contact and hysteresis quantities. It does not copy tensile peak, rupture, or post-peak failure analysis.

## Integrated report

```matlab
reportConfig = mechanics.config.compressionStudyReportConfig();
reportConfig.outputFolder = "results/compression-study/report";
reportFiles = mechanics.io.exportCompressionStudyReport( ...
    study, reportConfig);
```

Each maintained report figure is written as both the configured image format and an editable MATLAB `.fig`. The Markdown report embeds only the image file.

The report exporter owns persistent report figures. The driver retains only interactive diagnostics that provide information absent from the maintained report.

## Comparing completed studies

Process every material or condition independently, then compare the completed results:

```matlab
comparisonConfig = mechanics.config.compressionStudyComparisonConfig();
comparison = mechanics.workflow.compareCompressionStudies( ...
    [studyA, studyB], ...
    ["Condition A", "Condition B"], ...
    comparisonConfig);
```

The comparison validates stress and strain measures and processed units, preserves the input studies, namespaces repeated specimen identifiers, and reuses the common population and group-comparison workflows. It does not re-import data or repeat fitting.

## Sign contract

Instrument signs and stored mechanical signs are separate concerns. The maintained internal state uses physical signs:

```text
tension:     displacement > 0, strain > 0, stress > 0, stretch > 1
compression: displacement < 0, strain < 0, stress < 0, 0 < stretch < 1
```

Peak force, peak displacement, and other cycle quantities may remain positive reporting magnitudes. Plotting positive compression magnitudes does not alter the stored mechanical state.

The incompressible uniaxial models used in tension can be fitted directly to compression. No post-processing sign inversion is applied before fitting.

## Validation

Real compression datasets require visual confirmation of cycle selection, first-sample zeroing, physical sign normalization, fitting range, area assumptions, and explicit protocol exclusions.

For the current experiment, a crosshead speed of `20 mm/min` should be reported as a protocol deviation if strict ASTM D575 Method A compliance is claimed.