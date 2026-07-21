# Constitutive fit residual diagnostics

Phase 18 checks whether fitting residuals behave like unstructured model error
or retain systematic patterns that may indicate model mismatch, preprocessing
artifacts, or isolated anomalous observations.

## Usage

```matlab
fitResult = mechanics.fitting.fitModel(...);

diagnostics = mechanics.fitting.analyzeFitResiduals(fitResult);
```

## Diagnostics

The analysis reports:

- residual mean and standard deviation;
- RMSE, MAE, and maximum absolute residual;
- lag-one residual autocorrelation;
- residual correlation with deformation;
- correlation between absolute residual and predicted-stress magnitude;
- standardized-residual outlier flags.

The overall flag is:

```matlab
diagnostics.hasSystematicStructure
```

It becomes true when at least one configured diagnostic threshold is exceeded.

## Default screening thresholds

```matlab
config.standardizedResidualThreshold = 3.0;
config.autocorrelationThreshold = 0.50;
config.deformationCorrelationThreshold = 0.50;
config.heteroscedasticityCorrelationThreshold = 0.50;
```

These thresholds are screening criteria, not formal hypothesis tests. Residual
structure should be interpreted together with the deformation range, sampling
density, constitutive model, and measurement process.

## Interpretation

- Strong lag-one autocorrelation indicates ordered residual structure.
- Correlation with deformation indicates systematic under- or over-prediction
  across the fitting window.
- Increasing residual magnitude with predicted stress indicates possible
  heteroscedasticity.
- Large standardized residuals identify observations that merit inspection;
  they are not removed automatically.

## Plot and export

```matlab
mechanics.plotting.plotFitResidualDiagnostics(diagnostics);

files = mechanics.io.exportFitResidualDiagnostics( ...
    diagnostics, "results/fit-residual-diagnostics");
```

Exported files:

```text
residual_observations.csv
residual_metrics.csv
fit_residual_diagnostics.mat
```
