# Constitutive fit stability across deformation windows

Phase 17 evaluates how fitted constitutive parameters change when the maximum
deformation included in the fit is varied.

## Motivation

A parameter estimate can fit the complete curve well while depending strongly
on the selected deformation range. This analysis fits the same model over a
sequence of nested windows and reports whether parameter values remain stable.

## Usage

```matlab
config = mechanics.config.fitWindowStabilityConfig();
config.windowFractions = [0.25, 0.40, 0.55, 0.70, 0.85, 1.00];

stability = mechanics.fitting.analyzeFitWindowStability( ...
    modelName, deformation, stress, context, fitConfig, config);
```

For a fraction `f`, the upper deformation limit is

```text
xmin + f * (xmax - xmin)
```

so every window starts at the same minimum deformation and extends farther into
the measured response.

## Outputs

```text
windowSummary
parameterSummary
parameterMatrix
successMask
referenceParameters
stable
hasUnstableParameter
```

The default reference is the largest successful window. For each parameter,
the relative range is

```text
(maximum - minimum) / abs(reference)
```

with a numerical floor near zero. Parameters exceeding the configured threshold
are flagged as unstable.

## Interpretation

Strong window dependence may indicate:

- the parameter describes only a restricted deformation regime;
- multiple parameters compensate differently as more nonlinear data enter;
- the selected constitutive model does not represent the complete curve;
- low-strain data do not contain enough information for higher-order terms.

Window stability complements bootstrap uncertainty and identifiability. It does
not replace them.

## Export

```matlab
files = mechanics.io.exportFitWindowStability( ...
    stability, "results/fit-window-stability");
```

Exported files:

```text
fit_window_summary.csv
fit_window_parameters.csv
fit_window_stability.mat
```
