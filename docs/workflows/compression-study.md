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

## One study

A study contains several specimens from one material or experimental condition. Input is a manifest table or manifest file with:

```text
File
SpecimenId
InitialArea
```

`InitialLength` and `Include` are optional. The configured default initial length is used when `InitialLength` is absent.

```matlab
config = mechanics.config.compressionStudyConfig();
config.defaultInitialLength = 25;
config.specimen.fitting.enabled = true;
config.population.config.bootstrap.enabled = true;

study = mechanics.workflow.runCompressionStudy( ...
    "compression_manifest.csv", config);
```

The result contains:

```text
study.manifest
study.analysis
study.population
study.populationStatus
study.sourceFiles
study.config
```

The manifest describes ingestion only. Experimental group labels are not inferred from it.

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

Peak force, peak displacement, and other report-oriented cycle quantities may remain positive magnitudes. Those values do not alter the processed mechanical state.

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
- contact or zero-reference handling;
- physical sign normalization;
- fitting range and area assumptions.
