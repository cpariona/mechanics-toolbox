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

The maintained zero-reference diagnostic is intentionally local. `tensileStudyReportConfig.zeroReferenceDiagnosticHalfWindowPoints` controls how many acquisition samples on each side of the selected mechanical-zero index are shown. The diagnostic should make the selected zero visible rather than reproduce the full test curve.

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

The individual tangent-modulus figure marks the configured summary interval and overlays the stored median tangent-modulus summary for each specimen across that interval. The legend reports the corresponding summary value so the plotted local derivative and the scalar value used by the study remain explicitly connected.

## Constitutive fitting

```matlab
fitting = config.datasetAnalysis.fitting;
fitting.enabled = true;
fitting.modelNames = [ ...
    "neo-hookean"; ...
    "mooney-rivlin"; ...
    "yeoh-second-order"; ...
    "yeoh-third-order"];
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

When completed, the shared population result contains stress-strain curves, tangent-modulus aggregation, scalar metrics, individual model-selection consensus, and individually selected-model parameter summaries.

The maintained model-selection contract is descriptive and does not refit the population. `study.population.modelSelection` stores the individual selections, candidate selection counts and fractions, and a unique selection-frequency consensus when one exists. If all eligible specimens selected the same model, the existing individually selected-model parameter population already represents that consensus and no second consensus-model parameter population is generated.

If selections are mixed, parameter summaries remain grouped by each specimen's individually selected model. A consensus-model refit is reserved for explicit advanced workflows that require one common-model parameterization; it is not part of the standard tensile study or report.

The same standard parameter population also stores registry-derived initial shear modulus values when available. These values are derived from the selected specimen fits through `mechanics.statistics.deriveInitialShearModulus`; plotting does not duplicate constitutive formulas.

## Study bundle

The maintained export configuration is:

```matlab
config.export.enabled = true;
config.export.outputFolder = "results/my-study";
config.export.saveStudyMat = true;
config.export.saveTables = true;
config.export.savePopulation = true;
```

The population portion of the standard bundle contains:

```text
population_curve.csv
population_metrics.csv
population_tangent_modulus.csv
individual_model_selection_summary.csv
individual_selected_model_parameter_values.csv
individual_selected_model_parameter_summary.csv
```

The full study bundle also contains `tensile_study.mat`, study/dataset summaries, peak summary when available, and provenance.

`tensile_study.mat` contains the complete `study`, including `study.config` and `study.population`. No separate configuration MAT or population MAT is generated inside the study bundle.

`mechanics.io.exportPopulationAnalysis` remains usable independently and writes `population_analysis.mat` by default. Integrated study exporters reuse its table generation with MAT persistence disabled to avoid duplication.

## Reporting

```matlab
reportConfig = mechanics.config.tensileStudyReportConfig();
reportConfig.outputFolder = "results/my-study/report";
reportFiles = mechanics.io.exportTensileStudyReport(study, reportConfig);
```

The population section reports the distribution of individual model selections, the selection-frequency consensus when unique, whether that consensus is unanimous, and the individually selected-model parameter summary. Reporting only consumes `study.population`; it does not perform fitting, model selection, or a consensus refit.

Standard figures include individual curves, population response, peak metrics, specimen tangent modulus, population tangent modulus when available, selected-model parameters across specimens, registry-derived initial shear modulus across specimens, and local zero-reference diagnostics. The parameter and initial-shear figures visualize the same standard population already reported in the study; they do not represent a second consensus-model population.

Every maintained figure is exported as the configured image format and an editable MATLAB `.fig`. Figure inclusion remains configurable through `tensileStudyReportConfig`.

## Downstream constitutive workflows

Group comparison, parameter inference, explicit consensus-model refitting, constitutive reporting, and application-range characterization consume completed results. They remain optional and should not re-import or reprocess specimens.

A consensus-model refit is appropriate only when a downstream workflow requires every specimen to share one constitutive model. It must not be run merely to reproduce the same parameter summary already present in the standard study population.

## Tensile application-range characterization

The maintained add-on is documented in [`tensile-application-range-characterization.md`](tensile-application-range-characterization.md).

Its purpose is to estimate one shared hyperelastic parameter set from the already processed tensile loading curves inside a configured interval, such as engineering strain from `0` to `0.30`.

It consumes one completed tensile study, preserves equal influence per specimen, selects parsimoniously when candidate models are practically equivalent, and does not replace the standard tensile study.

## Study comparison

```matlab
comparison = mechanics.workflow.compareTensileStudies( ...
    [studyA, studyB], ...
    ["Condition A", "Condition B"], ...
    mechanics.config.tensileStudyComparisonConfig());
```

The comparison reuses maintained population and group-comparison logic without recalculating the standard study fitting pipeline.

## Relationship to joint material characterization

Comparing two tensile studies evaluates differences between experimental groups within one mode. Tensile application-range characterization specializes one completed tensile study to a configured loading interval. Neither is joint material characterization.

Joint tension-compression characterization estimates one constitutive parameter set from independent modes and is documented in [`joint-material-characterization.md`](joint-material-characterization.md).
