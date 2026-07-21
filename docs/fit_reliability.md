# Integrated constitutive-fit reliability

Phase 19 combines the principal diagnostics from Phases 15-18 into one screening assessment.

## Inputs

```matlab
assessment = mechanics.fitting.assessFitReliability( ...
    fitResult, uncertainty, identifiability, ...
    windowStability, residualDiagnostics);
```

The assessment considers:

- optimizer convergence;
- normalized RMSE and R-squared;
- bootstrap refit success;
- parameter identifiability;
- stability across deformation windows;
- systematic residual structure.

## Status values

```text
reliable
caution
unreliable
incomplete
```

`incomplete` is returned only when `requireAllDiagnostics` is enabled and one or more optional diagnostic structures are missing.

The classification is a screening summary. It does not replace inspection of the underlying tables, curves, residuals, or bootstrap distributions.

## Outputs

```text
status
flagCount
availableComponentCount
missingComponentCount
componentSummary
flaggedComponents
missingComponents
```

## Export

```matlab
files = mechanics.io.exportFitReliability( ...
    assessment, "results/fit-reliability");
```

Generated files:

```text
fit_reliability_components.csv
fit_reliability_summary.csv
fit_reliability.mat
```
