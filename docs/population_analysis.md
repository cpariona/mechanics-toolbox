# Replicate population analysis

Phase 9 aggregates successfully processed specimens after specimen-level quality
control and fitting.

## Responsibilities

The population layer provides:

- interpolation onto a common strain grid;
- mean stress-strain response;
- standard deviation and standard error;
- bootstrap confidence intervals;
- descriptive statistics for scalar specimen metrics;
- aggregation of parameters from selected constitutive models;
- export of population results.

## Common strain range

The default range is the intersection covered by every processed specimen:

```matlab
config.strainRangeMode = "common-overlap";
```

An explicit range is also supported:

```matlab
config.strainRangeMode = "explicit";
config.explicitStrainRange = [0, 0.8];
```

The explicit range must be covered by every included specimen.

## Bootstrap confidence interval

```matlab
config.bootstrap.enabled = true;
config.bootstrap.iterations = 2000;
config.bootstrap.confidenceLevel = 0.95;
config.bootstrap.randomSeed = 1;
```

Bootstrap resampling is performed over specimens, not over individual points
within one specimen.

## Workflow

```matlab
population = mechanics.workflow.analyzeSpecimenPopulation( ...
    analysis, config);
```

The input `analysis` is the result of:

```matlab
mechanics.workflow.analyzeExtractedDataset
```

## Results

```text
population.curves
population.metrics
population.modelParameters
population.specimenIds
population.specimenCount
```

`population.modelParameters.values` is a long table containing one row per
specimen and fitted parameter.

`population.modelParameters.summary` reports the mean, standard deviation,
coefficient of variation, and confidence interval for each model parameter.

## Export

```matlab
mechanics.io.exportPopulationAnalysis(population, outputFolder);
```

The export contains:

- `population_curve.csv`;
- `population_metrics.csv`;
- `selected_model_parameter_values.csv`;
- `selected_model_parameter_summary.csv`;
- `population_analysis.mat`.
