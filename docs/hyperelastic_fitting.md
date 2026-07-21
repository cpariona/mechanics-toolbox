# Hyperelastic fitting

Phase 3 fits registered uniaxial hyperelastic models without coupling model equations to the optimizer.

## Entry point

```matlab
result = mechanics.fitting.fitModel(modelName, deformation, stress, context, config);
```

The same `context` used to evaluate a model defines the deformation and stress measures used during fitting.

## Optimizer

The implementation uses MATLAB `fminsearch`. Parameter bounds are imposed through a smooth transformation between bounded physical parameters and unconstrained optimizer variables. No Optimization Toolbox is required.

## Multi-start strategy

`config.numberOfStarts` controls the number of initial guesses. The first start is the configured initial guess. Remaining starts are generated reproducibly using `config.randomSeed`.

## Output contract

The result contains model and parameter names, fitted parameters, predictions, residuals, metrics, optimizer status, configuration, and all individual starts.

## Metrics

The reported metrics are SSE, MSE, RMSE, normalized RMSE, MAE, maximum absolute error, R-squared, AIC, and BIC. These metrics describe fit quality; they do not establish physical validity or parameter identifiability.

## Current limitations

- Uniaxial data only.
- Least-squares stress residuals only.
- No confidence intervals or profile likelihood.
- No automatic fitting-window selection.
- No physical admissibility checks beyond registered parameter bounds.
