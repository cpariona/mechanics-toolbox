# Robust model selection

A low fitting error over the complete experimental curve does not guarantee a
stable constitutive model. Hyperelastic parameters may change substantially when
the fitted deformation range changes.

Phase 4 evaluates every candidate model over nested deformation windows.

## Workflow

```matlab
selectionConfig = mechanics.config.modelSelectionConfig();

study = mechanics.fitting.fitAcrossWindows( ...
    modelNames, deformation, stress, context, ...
    fitConfig, selectionConfig);
```

For each model and window, the toolbox stores the complete `fitResult`.

The summary reports:

- number of attempted and successful windows;
- number of converged fits;
- full-range RMSE, R-squared, AIC and BIC;
- mean, standard deviation and relative coefficient of variation of every
  fitted parameter;
- maximum relative parameter coefficient of variation;
- parameter-stability status;
- final eligibility.

## Eligibility

A model is eligible when:

1. every requested window was fitted successfully;
2. every successful fit converged, when convergence is required;
3. its maximum relative parameter coefficient of variation is below the
   configured threshold;
4. its full-window ranking metric is finite.

Eligibility is intentionally separate from ranking.

## Ranking

Eligible models can be ranked by:

- `BIC` (default);
- `AIC`;
- `RMSE`.

The ranking metric does not override stability requirements.

## Interpretation

Failure to obtain an eligible model is a valid result. It indicates that the
tested models, selected deformation windows, preprocessing choices, or parameter
constraints are not sufficiently stable for model selection.
