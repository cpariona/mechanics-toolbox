# Compression study

Compression data use the shared uniaxial mechanics pipeline after test-specific selection of the maintained measurement cycle and loading branch. Conditioning cycles are excluded from the analyzed response.

## Workflow hierarchy

- `compressionConfig` controls preprocessing and mechanics for one processed curve;
- `compressionSpecimenConfig` controls import, cycle selection, geometry, fitting, export, and reporting for one specimen;
- `compressionStudyConfig` coordinates several specimens belonging to one material or condition;
- `compressionStudyComparisonConfig` controls comparison of completed studies;
- `compressionStudyReportConfig` controls single-specimen report presentation.

No maintained workflow combines specimen ingestion, experimental grouping, comparison, plotting, and export in one compression-specific population layer.

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

Compression files may contain repeated conditioning cycles before the maintained measurement cycle. Only the selected branch is passed to stress-strain conversion, tangent-modulus estimation, constitutive fitting, and measurement Monte Carlo.

## One study from a workbook

A Zwick workbook may be passed directly to the study workflow:

```matlab
config = mechanics.config.compressionStudyConfig();
config.input.type = "workbook";
config.extraction.extractor = "auto";

study = mechanics.workflow.runCompressionStudy( ...
    "data/raw/compression.xlsx", config);
```

The shared Zwick adapter reads specimen sheets and the `Resultados` sheet. For
circular compression specimens, it recognizes `d0` and `h0`, calculates

```text
initialArea = pi*d0^2/4
initialLength = h0
```

and preserves the workbook specimen ID and sheet name. The normalized manifest
contains `File`, `SpecimenId`, `InitialLength`, `InitialArea`, `Include`, and
`Sheet`.

The same workflow also accepts a pre-extracted dataset, a workbook list, or a
manifest. Manifest input requires `File`, `SpecimenId`, and `InitialArea`;
`InitialLength`, `Include`, and `Sheet` are optional.

## ASTM D575 Method A convention

The maintained real-experiment workflow follows the Method A cycle structure:

- three successive compression cycles are expected;
- the first two cycles condition the specimen;
- the last complete cycle is selected;
- the loading branch of that cycle is analyzed;
- the first selected observation defines the mechanical zero;
- no preload threshold is applied.

A maintained driver is available at:

```text
studies/compression/run_compression_experiment.m
```

The driver keeps paths, exclusions, analysis settings, result saving, and
experiment plots in one editable file without duplicating reusable extraction
or mechanics implementation.

## Manual exclusions

Standard compliance and experimental suitability are not inferred by the
extractor. Exclusions are explicit and follow workbook extraction order:

```matlab
config.specimens.excludeIndices = [1; 2];
config.specimens.exclusionReason = ...
    "Initial thickness outside ASTM D575 tolerance";
```

Excluded rows remain visible in `study.manifest` and
`study.analysis.summary` with `Include=false` and `Status="skipped"`. Population
analysis uses only processed records.

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
```

The manifest describes ingestion and inclusion only. Experimental group labels
are not inferred from it.

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

Peak force, peak displacement, and other report-oriented cycle quantities may remain positive magnitudes. Those values do not alter the processed mechanical state. Plotting positive compression magnitudes is a presentation choice and does not change stored values.

This contract ensures that engineering strain, true strain, stretch, area evolution, true stress, tangent modulus, constitutive fitting, and measurement Monte Carlo use one representation.

## Constitutive fitting

The same incompressible uniaxial models used in tension can be fitted directly to compression:

```matlab
config.specimen.fitting.enabled = true;
config.specimen.fitting.modelNames = ...
    ["neo-hookean", "mooney-rivlin", "yeoh"];
```

No post-processing sign inversion is applied before fitting.

## Validation

Real compression datasets require visual confirmation of:

- exclusion of conditioning cycles;
- selection of the maintained measurement cycle and loading branch;
- first-sample zero-reference behavior;
- physical sign normalization;
- fitting range and area assumptions;
- explicit exclusion of specimens that do not satisfy the intended protocol.

For the current experiment, a crosshead speed of `20 mm/min` should be reported
as a protocol deviation if strict ASTM D575 Method A compliance is claimed.
