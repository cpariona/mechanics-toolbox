# Tensile study

The tensile workflow coordinates input normalization, specimen selection, preprocessing, loading segmentation, quality assessment, mechanical processing, constitutive fitting, peak descriptors, population analysis, export, and provenance capture.

## Maintained entrypoint

```matlab
config = mechanics.config.tensileStudyConfig();
config.extraction.defaultInitialLength = 25;
config.datasetAnalysis.fitting.enabled = true;
config.export.enabled = true;
config.export.outputFolder = "results/my-study";

study = mechanics.workflow.runTensileStudy(inputValue, config);
```

Supported inputs are a single workbook, workbook list, manifest, or pre-extracted dataset. All inputs are normalized before common downstream analysis.

The maintained real-experiment driver is:

```text
studies/tension/run_tensile_experiment.m
```

Experiment-specific paths, exclusions, assumptions, settings, optional analyses, and distinct interactive inspection figures remain in the driver. Reusable implementation remains under `src/+mechanics`.

## Specimen selection and zero reference

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

## Mechanics and tangent modulus

```matlab
mechanicsConfig = config.datasetAnalysis.processingConfig.mechanics;
mechanicsConfig.strainMeasure = "engineering";
mechanicsConfig.stressMeasure = "engineering";
mechanicsConfig.areaEvolution = "incompressible";
config.datasetAnalysis.processingConfig.mechanics = mechanicsConfig;

analysis = config.datasetAnalysis.processingConfig.analysis;
analysis.modulusMethod = "local-linear";
analysis.derivativeWindowStrain = 0.02;
analysis.summaryStrainRange = [0.00, 0.05];
config.datasetAnalysis.processingConfig.analysis = analysis;
```

The stored tensile state uses positive displacement, strain, and stress, with stretch greater than one. Plot trimming affects only `tangentModulusForPlot`; the complete derivative remains available for numerical summaries.

## Constitutive fitting

```matlab
fitting = config.datasetAnalysis.fitting;
fitting.enabled = true;
fitting.modelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
fitting.context.deformationMeasure = "engineering-strain";
fitting.context.stressMeasure = "nominal";
config.datasetAnalysis.fitting = fitting;
```

Measurement Monte Carlo is configured under `config.datasetAnalysis.fitting.measurementMonteCarlo`. Geometry uncertainty is configured under `config.datasetAnalysis.processingConfig.uncertainty.geometry`.

## Population analysis

```matlab
population = config.population;
population.enabled = true;
population.config.centralStatistic = "median";
population.config.strainGridPointCount = 201;
population.config.minimumSpecimens = 2;
config.population = population;
```

When completed, the shared population result contains stress-strain curves, tangent-modulus aggregation, scalar metrics, and selected-model parameter summaries.

## Study bundle

The maintained export configuration is:

```matlab
config.export.enabled = true;
config.export.outputFolder = "results/my-study";
config.export.saveStudyMat = true;
config.export.saveTables = true;
config.export.savePopulation = true;
```

The default bundle contains:

```text
tensile_study.mat
study_summary.csv
dataset_summary.csv
peak_summary.csv
provenance.csv
population_curve.csv
population_metrics.csv
population_tangent_modulus.csv
selected_model_parameter_values.csv
selected_model_parameter_summary.csv
```

`tensile_study.mat` contains the complete `study`, including `study.config` and `study.population`. No separate configuration MAT or population MAT is generated inside the study bundle.

`mechanics.io.exportPopulationAnalysis` remains usable independently and writes `population_analysis.mat` by default. Integrated study exporters reuse its table generation with MAT persistence disabled to avoid duplication.

## Reporting

```matlab
reportConfig = mechanics.config.tensileStudyReportConfig();
reportConfig.outputFolder = "results/my-study/report";
reportFiles = mechanics.io.exportTensileStudyReport(study, reportConfig);
```

Standard figures include individual curves, population response, peak metrics, specimen tangent modulus, population tangent modulus when available, and zero-reference diagnostics. Every maintained figure is exported as the configured image format and an editable MATLAB `.fig`.

## Downstream constitutive workflows

Selected-parameter population analysis, group comparison, parameter inference, consensus-model selection, constitutive reporting, and future application-range characterization consume completed results. They remain optional and should not re-import or reprocess specimens.

## Tensile application-range characterization

The planned maintained add-on is documented in [`tensile-application-range-characterization.md`](tensile-application-range-characterization.md).

Its purpose is to estimate one shared hyperelastic parameter set from the already processed tensile loading curves inside a configured interval, such as engineering strain from `0` to `0.30`.

It will:

- consume one completed tensile study;
- reuse maintained fitting, model-registry, ranking, plotting, and export contracts where physically identical;
- preserve equal influence per specimen;
- select parsimoniously when candidate models are practically equivalent;
- expose registry-derived reference properties such as `mu0`;
- audit sensitivity to the fit-range boundary;
- optionally evaluate a fixed tensile-calibrated model on compression data without refitting.

It will not re-import raw files, duplicate the tensile workflow, perform wave or incremental analysis, or replace joint material characterization.

## Study comparison

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    [studyA, studyB], ...
    ["Condition A", "Condition B"], ...
    mechanics.config.tensileStudyComparisonConfig());

files = mechanics.io.exportTensileStudyComparison( ...
    comparison, "results/tensile-study-comparison");
```

The comparison reuses maintained population and group-comparison logic. The dedicated exporter writes study and compatibility summaries, pairwise scalar metrics, mean curves and curve differences with available confidence intervals, a maintained PNG/FIG figure pair, the complete MAT result, and a concise Markdown report.

The exporter does not recalculate statistics and does not duplicate individual study bundles or constitutive-parameter reporting. Automated tests use synthetic completed studies. Real two-study validation remains pending because no representative pair of tensile study datasets is currently available.

## Relationship to joint material characterization

Comparing two tensile studies evaluates differences between experimental groups within one mode. Tensile application-range characterization specializes one completed tensile study to a configured loading interval. Neither is joint material characterization.

Joint tension-compression characterization estimates one constitutive parameter set from independent modes and is documented in [`joint-material-characterization.md`](joint-material-characterization.md).
