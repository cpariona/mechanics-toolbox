# Compression study

The compression workflow imports one tabular specimen, detects complete preparation cycles, selects the configured cycle and branch, normalizes the compression sign convention, and runs the common uniaxial processing pipeline.

```matlab
config = mechanics.config.compressionStudyConfig();
config.geometry.initialLength = 25;
config.geometry.initialArea = 100;
study = mechanics.workflow.runCompressionStudy("compression.csv", config);
```

## Required input

The source file must contain numeric force and displacement columns recognized by `mechanics.config.excelImportConfig`. Optional time and measured-area data are preserved. The default calibrated length for population compression manifests is 25 mm when `InitialLength` is omitted.

## Cycle selection and mechanics

```matlab
config.cycle.selection = "last-complete-cycle";
config.cycle.branch = "loading";
config.cycle.loadingDirection = "increasing";
config.signConvention = "positive-compression";
```

The complete cycle remains available for hysteresis calculations, while the selected branch is used for tangent modulus and optional constitutive fitting.

## Constitutive fitting

The same incompressible uniaxial models used in tension can be fitted to compression data:

```matlab
config.fitting.enabled = true;
config.fitting.modelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
```

The public compression curve remains positive. Internally, fitting uses negative engineering strain and negative nominal stress so the constitutive models evaluate stretches below one.

Measurement Monte Carlo refitting can perturb gauge length, area, force, and displacement:

```matlab
mc = config.fitting.measurementMonteCarlo;
mc.enabled = true;
mc.sampleCount = 500;
mc.initialLengthStd = 0.10;
mc.initialAreaStd = 0.20;
mc.forceStd = 0.01;
mc.displacementStd = 0.005;
config.fitting.measurementMonteCarlo = mc;
```

Successful results are stored in `study.specimen.measurementMonteCarloFit`.

## Cycle metrics

The workflow reports peak force, displacement, stress, strain, loading energy, recovered energy, hysteresis energy, hysteresis fraction, hysteresis energy density, and tangent modulus.

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
config.comparison.enabled = true;

population = mechanics.workflow.runCompressionPopulationStudy( ...
    "compression_manifest.csv", config);
```

For each valid group the workflow produces a population curve, specimen metrics, fitted-parameter tables, and status information. When at least two groups are valid, the common group-comparison workflow reports curve and scalar-metric comparisons.

## Area units

Measured area can be normalized automatically to mm2:

```matlab
config.import.currentAreaUnit = "cm2";
config.import.normalizeCurrentAreaUnits = true;
```

Supported units include `um2`, `mm2`, `cm2`, `m2`, and `in2` with common textual variants.

## Export and figures

```matlab
config.export.enabled = true;
config.export.outputFolder = "results/compression-population";
config.export.saveFigures = true;
```

Population export includes:

```text
compression_population_summary.csv
<Group>_population_curve.csv
<Group>_metrics.csv
<Group>_parameters.csv
compression_group_metric_comparison.csv
compression_population_curves.png
compression_hysteresis_by_group.png
compression_modulus_by_group.png
compression_population_study.mat
```

Single-specimen export continues to provide processed curves, cycle metrics, a MAT study file, a Markdown report, and diagnostic figures.

Cycle detection, contact detection, sign normalization, uncertainty inputs, and fitting windows remain configuration-dependent and should be checked visually when real experimental files are introduced.
