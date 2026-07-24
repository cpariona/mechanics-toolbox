# Constitutive fit diagnostics

Each diagnostic has its own configuration contract. `fitDiagnosticsWorkflowConfig` composes these lower-level configurations when the complete diagnostic workflow is used.

## Bootstrap uncertainty

Residual bootstrap resampling refits the selected model to synthetic responses built from centered fitted residuals. It reports parameter and prediction intervals and the successful-refit fraction.

```matlab
config = mechanics.config.fitUncertaintyConfig();
uncertainty = mechanics.fitting.bootstrapFitUncertainty( ...
    fitResult, config);
```

The intervals are conditional on the selected model, preprocessing, parameter bounds, and residual resampling assumptions. They do not include geometry uncertainty or model-form error.

## Parameter identifiability

```matlab
config = mechanics.config.fitIdentifiabilityConfig();
diagnostics = mechanics.fitting.analyzeFitIdentifiability( ...
    fitResult, uncertainty, config);
```

The analysis screens parameter coefficients of variation, interval widths, boundary concentration, and bootstrap parameter correlation. A low fitting error does not guarantee identifiable individual parameters.

## Stability across deformation windows

```matlab
config = mechanics.config.fitWindowStabilityConfig();
stability = mechanics.fitting.analyzeFitWindowStability( ...
    modelName, deformation, measuredStress, context, ...
    fitConfig, config);
```

The same model is fitted over nested maximum-deformation windows. Parameter ranges are compared with a configurable reference and threshold. Strong dependence on the fitting window may indicate limited information, parameter compensation, or model mismatch.

## Residual diagnostics

```matlab
config = mechanics.config.residualDiagnosticsConfig();
diagnostics = mechanics.fitting.analyzeFitResiduals(fitResult, config);
```

The analysis reports residual magnitude, lag-one autocorrelation, residual correlation with deformation, residual-magnitude correlation with predicted stress, and standardized-residual outliers. These are screening diagnostics; observations are not removed automatically.

## Integrated reliability

```matlab
config = mechanics.config.fitReliabilityConfig();
assessment = mechanics.fitting.assessFitReliability( ...
    fitResult, uncertainty, identifiability, ...
    windowStability, residualDiagnostics, config);
```

Possible statuses are:

```text
reliable
caution
unreliable
incomplete
```

The classification combines convergence, fit quality, bootstrap success, identifiability, window stability, and residual structure. Component-level results remain the primary evidence.

## Integrated entrypoint

```matlab
fitConfig = mechanics.config.fittingConfig();
workflowConfig = mechanics.config.fitDiagnosticsWorkflowConfig();

analysis = mechanics.workflow.runFitDiagnostics( ...
    modelName, deformation, measuredStress, context, ...
    fitConfig, workflowConfig);
```

Optional diagnostics can be enabled independently. When configured to continue, optional failures are captured in `analysis.diagnosticErrors`.

## Exports

The corresponding functions under `mechanics.io` export CSV summaries and complete MAT structures for uncertainty, identifiability, window stability, residual diagnostics, reliability, and the integrated workflow.
