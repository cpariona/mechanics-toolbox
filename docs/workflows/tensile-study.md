# Tensile study

The tensile workflow coordinates input normalization, specimen selection, preprocessing, loading segmentation, quality assessment, mechanical processing, constitutive fitting, peak descriptors, population analysis, export, and provenance capture.

## Maintained entrypoints

Run one study with:

```matlab
config = mechanics.config.tensileStudyConfig();
config.extraction.defaultInitialLength = 25;
config.datasetAnalysis.fitting.enabled = true;
config.export.enabled = true;
config.export.outputFolder = "results/my-study";

study = mechanics.workflow.runTensileStudy(inputValue, config);
```

Supported inputs are:

```text
single workbook
file list
batch manifest
pre-extracted dataset
```

All inputs are normalized before common downstream analysis.

The maintained real-experiment driver is:

```text
studies/tension/run_tensile_experiment.m
```

It contains experiment-specific paths, exclusions, measurement assumptions, settings, optional analyses, and manual inspection figures. Reusable implementation remains under `src/+mechanics`.

## Specimen selection and mechanical zero

```matlab
config.specimens.excludeIndices = [1, 4];
config.specimens.exclusionReason = ...
    "different preload or visible grip slip";

zeroReference = ...
    config.datasetAnalysis.processingConfig.preprocessing.zeroReference;
zeroReference.method = "preload-threshold";
zeroReference.preloadForce = 0.1;
zeroReference.sustainedPoints = 3;
config.datasetAnalysis.processingConfig.preprocessing.zeroReference = ...
    zeroReference;
```

Specimen-specific preload values can be supplied in workbook order through `config.specimens.preloadForceOverrides`.

## Mechanical measures

```matlab
mechanicsConfig = config.datasetAnalysis.processingConfig.mechanics;
mechanicsConfig.strainMeasure = "engineering";  % or "true"
mechanicsConfig.stressMeasure = "engineering";  % or "true"
mechanicsConfig.areaEvolution = "incompressible";
config.datasetAnalysis.processingConfig.mechanics = mechanicsConfig;
```

The stored tensile state uses positive displacement, strain, and stress, with stretch greater than one.

## Tangent modulus

```matlab
analysis = config.datasetAnalysis.processingConfig.analysis;
analysis.modulusMethod = "local-linear";
analysis.derivativeWindowStrain = 0.02;
analysis.summaryStrainRange = [0.00, 0.05];
analysis.modulusPlotStartStrain = NaN;
analysis.modulusPlotAutomaticStartFraction = 0.01;
config.datasetAnalysis.processingConfig.analysis = analysis;
```

Alternative methods are `local-quadratic`, `gradient-smoothed`, and `gradient`. Plot trimming affects only `tangentModulusForPlot`; the complete numerical derivative remains in `tangentModulus` and is used for summaries independently of display trimming.

## Constitutive fitting

```matlab
fitting = config.datasetAnalysis.fitting;
fitting.enabled = true;
fitting.modelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
fitting.context.deformationMeasure = "engineering-strain";
fitting.context.stressMeasure = "nominal";
config.datasetAnalysis.fitting = fitting;
```

The fitting context must match the processed deformation and stress representation.

Measurement-aware Monte Carlo refitting is configured under:

```text
config.datasetAnalysis.fitting.measurementMonteCarlo
```

Pointwise geometry uncertainty is configured under:

```text
config.datasetAnalysis.processingConfig.uncertainty.geometry
```

## Peak and post-peak descriptors

Tension-specific loading segmentation and peak analysis remain separate from the shared uniaxial mechanics core. Peak, post-peak, and energy quantities are descriptive; the workflow does not automatically classify rupture.

## Population analysis

```matlab
population = config.population;
population.enabled = true;
population.config.centralStatistic = "median";
population.config.strainGridPointCount = 201;
population.config.minimumSpecimens = 2;
config.population = population;
```

When enough processed specimens are available, the study contains:

```text
study.population.curves
study.population.tangentModulus
study.population.tangentModulusStatus
```

Population tangent modulus reuses each specimen's existing plotted derivative curve; it does not recompute derivatives.

## Downstream constitutive workflows

Selected-model parameters can be summarized without reprocessing specimens:

```matlab
parameterPopulation = mechanics.workflow.summarizeSelectedParameters( ...
    parameterBatch, mechanics.config.selectedParameterPopulationConfig());

files = mechanics.io.exportSelectedParameterPopulation( ...
    parameterPopulation, ...
    "results/my-study/selected-parameter-population");
```

Native fitted parameters remain separated by model family and parameter identity. A comparable initial shear modulus is derived while preserving the selected model:

```text
neo-hookean:    mu0 = mu
mooney-rivlin: mu0 = 2 * (C10 + C01)
yeoh:          mu0 = 2 * C10
```

Group comparison, selected-parameter inference, consensus-model selection, and constitutive reporting are composable downstream workflows. They should consume completed results rather than re-importing or refitting data unnecessarily.

## Study comparison

Compare completed studies with:

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    [studyA, studyB], ...
    ["Condition A", "Condition B"], ...
    mechanics.config.tensileStudyComparisonConfig());
```

The comparison validates compatible measures and units, preserves the input studies, namespaces repeated specimen identifiers, and reuses maintained population and group-comparison logic. Dedicated comparison export and reporting remain deferred in issue #25.

## Reporting and figure files

```matlab
reportConfig = mechanics.config.studyReportConfig();
reportConfig.outputFolder = "results/my-study/report";
reportFiles = mechanics.io.exportTensileStudyReport(study, reportConfig);
```

Standard report figures include individual stress-strain curves, population response, peak metrics, specimen tangent modulus, population tangent modulus when available, and zero-reference diagnostics.

Every maintained workflow figure is written as a pair with the same base name:

```text
figure_name.png   % or configured image format
figure_name.fig   % editable MATLAB figure
```

The Markdown report embeds only the image file. Manual figures created directly in the experiment driver are outside this persistence contract.

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

Raw acquisition data remain preserved while constitutive analysis uses the selected loading interval.