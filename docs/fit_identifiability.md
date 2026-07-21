# Constitutive fit identifiability diagnostics

Phase 16 converts bootstrap parameter samples into practical diagnostics for
parameter identifiability.

## Inputs

```matlab
fitResult = mechanics.fitting.fitModel(...);
uncertainty = mechanics.fitting.bootstrapFitUncertainty( ...
    fitResult, uncertaintyConfig);

diagnostics = mechanics.fitting.analyzeFitIdentifiability( ...
    fitResult, uncertainty);
```

## Diagnostics

Per parameter:

- bootstrap mean and standard deviation;
- coefficient of variation;
- confidence-interval width relative to the best-fit value;
- lower- and upper-bound hit fractions;
- weak-identifiability flags.

Across parameters:

- bootstrap correlation matrix;
- high-correlation parameter pairs;
- one overall `weaklyIdentified` flag.

## Default criteria

```matlab
config.coefficientOfVariationThreshold = 0.50;
config.relativeIntervalWidthThreshold = 1.00;
config.correlationThreshold = 0.95;
config.boundaryHitFractionThreshold = 0.10;
```

These are screening thresholds rather than universal statistical rules. They
should be interpreted together with experiment design, deformation range,
noise level, and constitutive-model structure.

## Interpretation

A low fitting error does not guarantee identifiable parameters. Two parameters
may compensate for one another and produce nearly identical stress-strain
curves. Strong bootstrap correlation or broad intervals indicate that the data
support the combined model response more clearly than the individual parameter
values.

## Plot and export

```matlab
mechanics.plotting.plotFitIdentifiability(diagnostics);

files = mechanics.io.exportFitIdentifiability( ...
    diagnostics, "results/fit-identifiability");
```

Exported files:

```text
parameter_identifiability.csv
parameter_correlation.csv
high_correlation_pairs.csv
fit_identifiability.mat
```
