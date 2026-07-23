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

Extracted specimens retain workbook order. Exclude known specimens by extraction index:

```matlab
config.specimens.excludeIndices = [1, 4];
config.specimens.exclusionReason = "different preload or visible grip slip";
```

The result records the excluded indices, specimen IDs, sheet names, and reason in `study.exclusion`.

## Mechanical zero and preload

The default zero reference is the first selected sample. A preload threshold is usually preferable when the acquisition begins before the intended reference state:

```matlab
processing = config.datasetAnalysis.processingConfig.preprocessing;
processing.zeroReference.method = "preload-threshold";
processing.zeroReference.preloadForce = 0.1;
processing.zeroReference.sustainedPoints = 3;
config.datasetAnalysis.processingConfig.preprocessing = processing;
```

Exceptional specimen-specific preload values can be supplied in workbook order. Use `NaN` to retain the global configuration:

```matlab
config.specimens.preloadForceOverrides = [0.5; 0.1; 0.1; 0.1; 0.1];
```

## Tangent modulus

Tangent modulus is estimated over strain-based local windows. The default method is local linear regression, which smooths and differentiates within the same local fit:

```matlab
analysis = config.datasetAnalysis.processingConfig.analysis;
analysis.modulusMethod = "local-linear";
analysis.derivativeWindowStrain = 0.02;
analysis.summaryStrainRange = [0.00, 0.05];
config.datasetAnalysis.processingConfig.analysis = analysis;
```

Alternative methods are `local-quadratic`, `gradient-smoothed`, and `gradient`. Smoothing used for derivative estimation does not modify the stress curves used in population averaging.

## Geometry uncertainty

Optional first-order propagation can quantify how standard uncertainty in initial gauge length and initial area affects each stress-strain point:

```matlab
uncertainty = config.datasetAnalysis.processingConfig.uncertainty.geometry;
uncertainty.enabled = true;
uncertainty.initialLengthStd = 0.10; % same length unit as initialLength
uncertainty.initialAreaStd = 0.20;   % same area unit as initialArea
config.datasetAnalysis.processingConfig.uncertainty.geometry = uncertainty;
```

The result is stored under `specimen.analysis.geometryUncertainty` and added to specimen-level curve exports. This propagation does not include force, displacement, preprocessing, or fitting uncertainty.

## Population response

Curves are interpolated linearly on a configurable common strain grid. No additional smoothing is applied before aggregation. The central curve can be a mean or median:

```matlab
config.population.config.centralStatistic = "mean";   % or "median"
config.population.config.strainGridPointCount = 201;
```

The 201 points form an interpolation grid; they do not represent experimental resolution.

## Units

The Zwick extractor reads variable names from row 2 and units from row 3 of each specimen sheet. Force and displacement are normalized internally to N and mm when the reported units are supported. Original units and conversion factors remain in the specimen results.

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

Titles are generated from the source filename unless `reportConfig.studyTitle` is set explicitly. Standard figures include individual stress-strain curves, the population response, peak metrics, tangent modulus, and zero-reference diagnostics. Axes include propagated units.

Peak metrics include peak force, peak displacement, peak stress, peak strain, post-peak force drop, residual force fraction, energy to peak, total recorded work, and energy density to peak. The toolbox no longer classifies fracture as detected or complete.

The report exporter only renders an existing `study` structure. It does not rerun extraction, fitting, peak analysis, or population statistics.
