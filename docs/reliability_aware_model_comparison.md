# Reliability-aware constitutive model comparison

Phase 21 compares several constitutive models on the same dataset while using
the Phase 20 diagnostic workflow for every candidate.

## Workflow

```matlab
fitConfig = mechanics.config.fittingConfig();
config = mechanics.config.modelComparisonWorkflowConfig();

comparison = mechanics.workflow.compareModelsWithDiagnostics( ...
    modelNames, deformation, measuredStress, context, fitConfig, config);
```

Each candidate is fitted and assigned a reliability status. Only models whose
status belongs to `allowedReliabilityStatuses` are eligible for final ranking.
The default eligible statuses are `reliable` and `caution`.

## Selection criteria

Supported criteria are:

- `aicc`;
- `aic`;
- `bic`;
- `rmse`;
- `normalized-rmse`.

The default is AICc because it penalizes unnecessary parameters and includes a
small-sample correction. Ranking is performed only among successfully fitted,
reliability-eligible models.

## Result

The returned structure contains the per-model diagnostic analyses, the
comparison table, the selected model, and the configuration used.

```matlab
disp(comparison.summary)
disp(comparison.selectedModelName)
```

The summary includes fit success, reliability status, eligibility, parameter
count, RMSE, normalized RMSE, R-squared, AIC, AICc, BIC, criterion value, rank,
and captured model-level errors.

## Export

```matlab
files = mechanics.io.exportModelComparison( ...
    comparison, "results/model-comparison");
```

Exported files:

```text
model_comparison_summary.csv
model_selection.csv
model_comparison.mat
```

The selected model is a screening recommendation. Constitutive plausibility,
parameter interpretation, and experimental design remain part of final model
acceptance.
