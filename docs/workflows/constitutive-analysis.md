# Constitutive analysis workflow

The constitutive workflow separates specimen fitting, diagnostic assessment, model selection, population summaries, group inference, and report rendering.

## Configuration hierarchy

The public configuration functions correspond to different execution layers:

- `fittingConfig` controls one constitutive fit;
- `fitDiagnosticsWorkflowConfig` composes uncertainty, identifiability, window-stability, residual, and reliability settings for one fitted model;
- `modelComparisonWorkflowConfig` compares candidate models for one specimen;
- `batchModelComparisonConfig` applies model comparison across specimens;
- `selectedParameterPopulationConfig` controls extraction and summary of selected-model parameters;
- `groupParameterInferenceConfig` controls between-group inference;
- `constitutiveStudyReportConfig` controls rendering and export only.

These configurations are intentionally separate. Higher-level configurations contain lower-level configurations when orchestration requires them.

## One model and one specimen

```matlab
fitConfig = mechanics.config.fittingConfig();
diagnosticConfig = mechanics.config.fitDiagnosticsWorkflowConfig();

analysis = mechanics.workflow.runFitDiagnostics( ...
    modelName, deformation, measuredStress, context, ...
    fitConfig, diagnosticConfig);

files = mechanics.io.exportFitDiagnostics( ...
    analysis, "results/fit-diagnostics");
```

The result contains the fitted parameters, bootstrap uncertainty, identifiability diagnostics, deformation-window stability, residual diagnostics, reliability classification, and captured optional-diagnostic errors. The exporter writes CSV and MAT results together with `fit_reliability.png` and the editable `fit_reliability.fig`.

## Compare candidate models

```matlab
config = mechanics.config.modelComparisonWorkflowConfig();
comparison = mechanics.workflow.compareModelsWithDiagnostics( ...
    modelNames, deformation, measuredStress, context, fitConfig, config);

files = mechanics.io.exportModelComparison( ...
    comparison, "results/model-comparison");
```

Only successfully fitted models with an allowed reliability status are eligible for ranking. Supported criteria include AICc, AIC, BIC, RMSE, and normalized RMSE. The exporter owns the maintained comparison figure and writes both `model_comparison.png` and `model_comparison.fig`.

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
config = mechanics.config.selectedParameterPopulationConfig();
config.minimumSpecimensPerSummary = 3;

population = mechanics.workflow.summarizeSelectedParameters(batch, config);
```

Parameters remain separated by model family and parameter name. The result includes a long-form specimen table, overall summaries, group summaries, bootstrap intervals when available, and extraction errors. `requireFiniteParameters` controls whether nonfinite selected parameters are rejected, while `continueOnExtractionError` controls whether one failed specimen aborts the complete summary.

## Descriptive group comparison

```matlab
comparison = mechanics.workflow.analyzeGroupComparison( ...
    groupedAnalysis, groupNames, mechanics.config.groupComparisonConfig());

files = mechanics.io.exportGroupComparison( ...
    comparison, "results/group-comparison");
```

For a two-group comparison, the exporter writes the group summaries, population bundles, pairwise curve and metric tables, MAT result, and the maintained `group_comparison.png` and `group_comparison.fig` figure pair. Comparisons with more than two groups retain their tabular and MAT outputs without inventing a pairwise figure.

## Group inference

```matlab
config = mechanics.config.groupParameterInferenceConfig();
inference = mechanics.workflow.compareSelectedParametersBetweenGroups( ...
    population, config);

files = mechanics.io.exportGroupParameterInference( ...
    inference, "results/group-parameter-inference");
```

Pairwise comparisons are performed separately for each model and parameter combination. Outputs include mean and median differences, bootstrap confidence intervals, Hedges' g, Cliff's delta, permutation p-values, and multiplicity-adjusted p-values. The exporter also writes `group_parameter_inference.png` and `group_parameter_inference.fig`, including an explicit no-successful-comparisons view when the result contains no finite estimates.

## Figure ownership

Maintained exporters own persistent workflow figures. Every maintained figure is written as a PNG image and an editable MATLAB FIG file with the same base name. Drivers should not call the corresponding plotter separately before invoking an exporter. Interactive driver figures are reserved for experiment-specific diagnostics that are not part of a maintained export contract.

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
