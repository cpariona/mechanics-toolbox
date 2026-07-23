# Compression study

The compression workflow imports one tabular specimen, detects complete preparation cycles, selects the configured cycle and branch, normalizes the compression sign convention, and runs the common uniaxial processing pipeline.

```matlab
config = mechanics.config.compressionStudyConfig();
config.geometry.initialLength = 25;
config.geometry.initialArea = 100;

study = mechanics.workflow.runCompressionStudy( ...
    "data/raw/compression.csv", config);
```

## Required input

The source file must contain numeric force and displacement columns recognized by `mechanics.config.excelImportConfig`. Optional time and measured-area data are preserved. The default calibrated length for population compression manifests is 25 mm when `InitialLength` is omitted.

## Cycle selection

```matlab
config.cycle.selection = "last-complete-cycle";
config.cycle.branch = "loading";
config.cycle.loadingDirection = "increasing";
```

Use `loadingDirection = "decreasing"` when instrument displacement becomes more negative during compression. `branch` also accepts `unloading` and `full-cycle`.

## Sign convention

The default convention reports compression force, displacement, stress, and strain as positive. Constitutive fitting internally converts the loading branch to negative engineering strain and negative nominal stress, which is the convention used by the registered hyperelastic models for stretches below one.

## Mechanical processing

The selected branch uses the shared uniaxial pipeline, including zero-reference correction, engineering or true measures, and tangent-modulus estimation.

```matlab
config.processing.preprocessing.zeroReference.method = "preload-threshold";
config.processing.preprocessing.zeroReference.preloadForce = 0.1;
```

## Constitutive fitting

The same incompressible uniaxial models used in tension can be fitted to compression data:

```matlab
config.fitting.enabled = true;
config.fitting.modelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
```

Results are stored under:

```text
study.specimen.modelSelection
```

Geometry-aware Monte Carlo refitting can be enabled for the selected model:

```matlab
config.fitting.geometryMonteCarlo.enabled = true;
config.fitting.geometryMonteCarlo.sampleCount = 200;
config.fitting.geometryMonteCarlo.initialLengthStd = 0.1;
config.fitting.geometryMonteCarlo.initialAreaStd = 0.2;
```

This is most useful when parameter differences between specimens or groups are comparable to the uncertainty introduced by specimen geometry. It is not required for routine exploratory fitting when geometry uncertainty is negligible relative to biological or manufacturing variability.

## Cycle metrics

The workflow reports peak force, peak displacement, peak stress, peak strain, loading energy, recovered energy, hysteresis energy, hysteresis fraction, and hysteresis energy density.

## Population and group analysis

Use a manifest with at least:

```text
File
SpecimenId
InitialArea
```

Optional columns are `Group`, `InitialLength`, and `Include`. When `InitialLength` is absent, the configured default of 25 mm is used.

```matlab
config = mechanics.config.compressionPopulationConfig();
config.defaultInitialLength = 25;
config.studyConfig.fitting.enabled = true;
config.population.bootstrap.enabled = true;

population = mechanics.workflow.runCompressionPopulationStudy( ...
    "compression_manifest.csv", config);
```

The result contains specimen records, a scalar summary, and one population stress-strain aggregate per group. Groups with fewer than `minimumSpecimensPerGroup` remain marked as insufficient.

## Area units

Table import can normalize measured area automatically to mm2:

```matlab
config.import.currentAreaUnit = "cm2";
config.import.normalizeCurrentAreaUnits = true;
```

Supported units include `um2`, `mm2`, `cm2`, `m2`, and `in2` with common textual variants.

## Export and figures

Single-specimen export includes processed curves, cycle metrics, a MAT study file, and report figures. Population export writes a study summary, one population curve per valid group, and a MAT file.

Cycle detection, contact detection, sign normalization, and fitted compression conventions should be checked visually for each new machine format or protocol.
