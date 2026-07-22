# Constitutive analysis workflow

The constitutive workflow separates specimen fitting, diagnostic assessment, model selection, population summaries, group inference, and report rendering.

## One model and one specimen

```matlab
fitConfig = mechanics.config.fittingConfig();
diagnosticConfig = mechanics.config.fitDiagnosticsWorkflowConfig();

analysis = mechanics.workflow.runFitDiagnostics( ...
    modelName, deformation, measuredStress, context, ...
    fitConfig, diagnosticConfig);
```

The result contains the fitted parameters, bootstrap uncertainty, identifiability diagnostics, deformation-window stability, residual diagnostics, reliability classification, and captured optional-diagnostic errors.

## Compare candidate models

```matlab
config = mechanics.config.modelComparisonWorkflowConfig();
comparison = mechanics.workflow.compareModelsWithDiagnostics( ...
    modelNames, deformation, measuredStress, context, fitConfig, config);
```

Only successfully fitted models with an allowed reliability status are eligible for ranking. Supported criteria include AICc, AIC, BIC, RMSE, and normalized RMSE.

## Compare models across specimens

Each specimen must provide `specimenId`, `deformation`, and `measuredStress`; `group` and `context` are optional.

```matlab
config = mechanics.config.batchModelComparisonConfig();
batch = mechanics.workflow.compareModelsAcrossSpecimens( ...
    specimens, modelNames, fitConfig, config);
```

The output preserves every specimen-level comparison and summarizes selected-model frequencies overall and by group.

## Selected-parameter summaries

```matlab
population = mechanics.workflow.summarizeSelectedParameters(batch);
```

Parameters remain separated by model family and parameter name. The result includes a long-form specimen table, overall summaries, group summaries, bootstrap intervals when available, and extraction errors.

## Group inference

```matlab
config = mechanics.config.groupParameterInferenceConfig();
inference = mechanics.workflow.compareSelectedParametersBetweenGroups( ...
    population, config);
```

Pairwise comparisons are performed separately for each model and parameter combination. Outputs include mean and median differences, bootstrap confidence intervals, Hedges' g, Cliff's delta, permutation p-values, and multiplicity-adjusted p-values.

## Integrated report

```matlab
config = mechanics.config.constitutiveStudyReportConfig();
config.outputFolder = "results/constitutive-study-report";
files = mechanics.io.exportConstitutiveStudyReport( ...
    batch, population, inference, config);
```

The exporter renders already-computed model-selection, parameter, and inferential results. It does not rerun fitting or statistical analysis.

## Interpretation limits

Model selection is conditional on the candidate models, parameter bounds, preprocessing, deformation range, reliability filters, and selection criterion. Parameters from different constitutive models must not be pooled. Statistical significance does not establish mechanical or biological relevance.
