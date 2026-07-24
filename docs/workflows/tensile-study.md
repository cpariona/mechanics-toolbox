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
config.datasetAnalysis.processingConfig.analysis = analysis;
```

Alternative methods are `local-quadratic`, `gradient-smoothed`, and `gradient`. Derivative smoothing does not modify the stress curves used in population averaging.

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
```

The common grid is an interpolation grid, not experimental resolution.

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

Standard figures include individual stress-strain curves, the population response, peak metrics, tangent modulus, and zero-reference diagnostics. Peak metrics retain descriptive peak, post-peak, and energy quantities without automatic rupture classification.
