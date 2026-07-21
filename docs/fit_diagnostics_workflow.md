# Integrated constitutive-fit diagnostics workflow

Phase 20 provides one entry point for fitting a constitutive model and running
the diagnostic stack introduced in Phases 15-19.

## Workflow

```matlab
fitConfig = mechanics.config.fittingConfig();
workflowConfig = mechanics.config.fitDiagnosticsWorkflowConfig();

analysis = mechanics.workflow.runFitDiagnostics( ...
    modelName, deformation, measuredStress, context, ...
    fitConfig, workflowConfig);
```

The returned structure contains:

- `fitResult`;
- `uncertainty`;
- `identifiability`;
- `windowStability`;
- `residualDiagnostics`;
- `reliability`;
- `diagnosticErrors`.

## Optional diagnostics

Bootstrap uncertainty, identifiability, deformation-window stability, and
residual diagnostics can be enabled independently. The constitutive fit itself
is mandatory.

When `continueOnOptionalDiagnosticError` is true, an optional diagnostic failure
is recorded in `diagnosticErrors` and the remaining diagnostics continue. The
final reliability assessment then marks that component as unavailable.

## Export

```matlab
files = mechanics.io.exportFitDiagnostics( ...
    analysis, "results/fit-diagnostics");
```

Exported files:

```text
fit_reliability_components.csv
fit_diagnostic_errors.csv
fit_diagnostics_summary.csv
fit_diagnostics.mat
```

The reliability classification remains a screening result. Component-level
outputs should be reviewed before reporting constitutive parameters.