# Bootstrap uncertainty for constitutive fitting

Phase 15 estimates uncertainty for one fitted constitutive model using residual
bootstrap resampling.

## Method

Given a fitted response

```text
y = y_hat + residual
```

centered residuals are sampled with replacement. Each synthetic response is
refitted with the same model and parameter bounds. The resulting parameter and
prediction distributions are summarized using percentile intervals.

## Usage

```matlab
config = mechanics.config.fitUncertaintyConfig();
config.sampleCount = 500;
config.confidenceLevel = 0.95;

uncertainty = mechanics.fitting.bootstrapFitUncertainty( ...
    fitResult, config);
```

Main outputs:

```text
parameterSamples
parameterLower
parameterMedian
parameterUpper
predictionLower
predictionMedian
predictionUpper
successfulFraction
```

## Plot

```matlab
mechanics.plotting.plotFitUncertainty(fitResult, uncertainty);
```

## Export

```matlab
files = mechanics.io.exportFitUncertainty( ...
    fitResult, uncertainty, "results/fit-uncertainty");
```

The export contains parameter intervals, prediction intervals, and the complete
MATLAB structures.

## Interpretation

The interval quantifies sensitivity to the observed residual structure under
the selected model. It does not account for uncertainty in specimen geometry,
model-form error, preprocessing choices, or dependence between observations.
