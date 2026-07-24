# End-to-end tensile study

The study workflow coordinates workbook extraction, specimen selection, loading-curve segmentation, quality assessment, mechanical processing, optional constitutive fitting, peak metrics, population analysis, export, and provenance capture.

```matlab
config = mechanics.config.tensileStudyConfig();
config.extraction.defaultInitialLength = 25;
config.datasetAnalysis.fitting.enabled = true;
config.export.enabled = true;
config.export.outputFolder = "results/my-study";
study = mechanics.workflow.runTensileStudy(filename, config);
```

A complete executable configuration for a real experiment is maintained at:

```text
studies/tension/run_tensile_experiment.m
```

This study driver is intended to be copied or adapted for an experimental campaign. It is not a simplified example and does not contain reusable implementation.

## Excluding specimens

```matlab
config.specimens.excludeIndices = [1, 4];
config.specimens.exclusionReason = "different preload or visible grip slip";
```

## Mechanical zero and preload

```matlab
processing = config.datasetAnalysis.processingConfig.preprocessing;
processing.zeroReference.method = "preload-threshold";
processing.zeroReference.preloadForce = 0.1;
processing.zeroReference.sustainedPoints = 3;
config.datasetAnalysis.processingConfig.preprocessing = processing;
```

Specimen-specific preload values can be supplied in workbook order through `config.specimens.preloadForceOverrides`.

## Tangent modulus

```matlab
analysis = config.datasetAnalysis.processingConfig.analysis;
analysis.modulusMethod = "local-linear";
analysis.derivativeWindowStrain = 0.02;
analysis.summaryStrainRange = [0.00, 0.05];

% Plot only: hide unstable values at the leading edge.
analysis.modulusPlotStartStrain = NaN;
analysis.modulusPlotAutomaticStartFraction = 0.01;

config.datasetAnalysis.processingConfig.analysis = analysis;
```

Alternative methods are `local-quadratic`, `gradient-smoothed`, and `gradient`. Derivative smoothing does not modify the stress curves used in population averaging.

`tangentModulus` always retains the complete numerical derivative. `tangentModulusForPlot` replaces only values before the configured plot start with `NaN`:

- `modulusPlotStartStrain = NaN` selects an automatic start;
- `modulusPlotAutomaticStartFraction` defines the skipped fraction of the complete strain span;
- a finite `modulusPlotStartStrain` specifies the first strain shown manually.

This plot-only trimming does not alter the reported mean or median modulus, the processed stress-strain curve, or constitutive fitting.

## Constitutive fitting measures

The fitting context describes how the constitutive model interprets deformation and which stress measure it returns:

```matlab
config.datasetAnalysis.fitting.context.deformationMeasure = ...
    "engineering-strain";
config.datasetAnalysis.fitting.context.stressMeasure = "nominal";
```

The default values remain engineering strain and nominal stress and should match the processed curve representation.

## Pointwise geometry uncertainty

```matlab
uncertainty = config.datasetAnalysis.processingConfig.uncertainty.geometry;
uncertainty.enabled = true;
uncertainty.initialLengthStd = 0.10;
uncertainty.initialAreaStd = 0.20;
config.datasetAnalysis.processingConfig.uncertainty.geometry = uncertainty;
```

Results are stored under `specimen.analysis.geometryUncertainty` and added to specimen-level curve exports.

## Measurement Monte Carlo for fitted parameters

After model selection, the selected full-window model can be refitted under repeated perturbations of geometry and signals:

```matlab
config.datasetAnalysis.fitting.enabled = true;
mc = config.datasetAnalysis.fitting.measurementMonteCarlo;
mc.enabled = true;
mc.sampleCount = 500;
mc.initialLengthStd = 0.10;
mc.initialAreaStd = 0.20;
mc.forceStd = 0.01;
mc.displacementStd = 0.005;
config.datasetAnalysis.fitting.measurementMonteCarlo = mc;
```

The result is stored in:

```text
specimen.measurementMonteCarloFit
```

and contains parameter samples, percentile limits, medians, and successful-refit statistics. This is separate from residual bootstrap uncertainty.

## Population response

```matlab
config.population.config.centralStatistic = "mean";   % or "median"
config.population.config.strainGridPointCount = 201;
config.population.config.minimumSpecimens = 2;
```

The common grid is an interpolation grid, not experimental resolution.

The population workflow produces both the stress response and, when enough processed specimens contain tangent-modulus analysis, a tangent-modulus population result:

```text
study.population.curves
study.population.tangentModulus
study.population.tangentModulusStatus
```

The tangent-modulus population result:

- interpolates each specimen's existing `tangentModulusForPlot` curve;
- does not recompute derivatives;
- selects a continuous strain interval supported by at least `minimumSpecimens`;
- preserves the interpolated specimen curves in `modulusMatrix`;
- records the effective support in `specimenCountByPoint`;
- reuses the configured central statistic and bootstrap settings.

Main fields are:

```text
study.population.tangentModulus.strain
study.population.tangentModulus.modulusMatrix
study.population.tangentModulus.centralModulus
study.population.tangentModulus.confidenceLower
study.population.tangentModulus.confidenceUpper
study.population.tangentModulus.specimenCountByPoint
study.population.tangentModulus.centralStatistic
```

If fewer than `minimumSpecimens` expose tangent-modulus curves, the remaining population analyses still run and `tangentModulusStatus` is `"unavailable"`.

## Selected constitutive parameters

Selected-parameter population analysis is a composable downstream workflow because it requires a batch model-comparison result rather than only the core tensile-study result:

```matlab
parameterPopulation = mechanics.workflow.summarizeSelectedParameters( ...
    parameterBatch, mechanics.config.selectedParameterPopulationConfig());

files = mechanics.io.exportSelectedParameterPopulation( ...
    parameterPopulation, "results/my-study/selected-parameter-population");
```

Native fitted parameters remain separated by model family and parameter name. The workflow also derives a common initial shear modulus while retaining the selected model identity:

```text
neo-hookean:    mu0 = mu
mooney-rivlin: mu0 = 2 * (C10 + C01)
yeoh:          mu0 = 2 * C10
```

Derived results are stored under:

```text
parameterPopulation.initialShearModulus.values
parameterPopulation.initialShearModulus.summary
parameterPopulation.initialShearModulus.errors
```

The maintained exporter writes the native-parameter tables, initial-shear-modulus tables, a MAT file, `selected_parameter_population.png`, and `initial_shear_modulus_population.png`.

## Units

The Zwick extractor reads variable names from row 2 and units from row 3. Force and displacement are normalized internally to N and mm when supported. Gauge length remains an explicit geometry input; for the calibrated specimens it should be configured as 25 mm when absent from the workbook.

## Main outputs

```text
study.dataset
study.exclusion
study.analysis
study.population
study.provenance
study.config
study.outputFiles
```

The full raw acquisition remains preserved while constitutive analysis uses the selected loading interval.

## Study reporting

```matlab
reportConfig = mechanics.config.studyReportConfig();
reportConfig.outputFolder = "results/my-study/report";
files = mechanics.io.exportTensileStudyReport(study, reportConfig);
```

Standard figures include individual stress-strain curves, the population response, peak metrics, specimen tangent-modulus curves, the population tangent-modulus response when available, and zero-reference diagnostics. Population tangent-modulus values are also exported to `population_tangent_modulus.csv`. Peak metrics retain descriptive peak, post-peak, and energy quantities without automatic rupture classification.
