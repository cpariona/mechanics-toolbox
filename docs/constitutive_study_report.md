# Final constitutive study report

Phase 25 integrates the outputs of Phases 22-24 into a single Markdown report and a standard figure set.

```matlab
config = mechanics.config.constitutiveStudyReportConfig();
config.outputFolder = "results/constitutive-study-report";
files = mechanics.io.exportConstitutiveStudyReport( ...
    batch, population, inference, config);
```

Required inputs:

- `batch`: result from `compareModelsAcrossSpecimens`;
- `population`: result from `summarizeSelectedParameters`;
- `inference`: result from `compareSelectedParametersBetweenGroups`.

The report includes model-selection frequencies, selected-model parameter summaries, group summaries, inferential comparisons, effect sizes, adjusted p-values, interpretation limits, and links to exported figures.

Default figures:

```text
model_selection.png
selected_parameters.png
group_parameter_inference.png
```

Each figure group can be disabled independently. The exporter does not rerun fitting, model comparison, bootstrap diagnostics, or inferential analysis. It renders already-computed results.
