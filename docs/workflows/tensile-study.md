# End-to-end tensile study

The study workflow coordinates workbook extraction, quality assessment, pre-fracture segmentation, mechanical processing, optional constitutive fitting, fracture metrics, population analysis, export, and provenance capture.

```matlab
config = mechanics.config.tensileStudyConfig();
config.extraction.defaultInitialLength = 25;
config.datasetAnalysis.fitting.enabled = true;
config.export.enabled = true;
config.export.outputFolder = "results/my-study";

study = mechanics.workflow.runTensileStudy(filename, config);
```

Main outputs:

```text
study.dataset
study.analysis
study.population
study.provenance
study.config
study.outputFiles
```

Specimen failures can be isolated according to the dataset-analysis configuration. The full raw acquisition remains preserved while constitutive analysis uses the selected pre-fracture interval.

## Study reporting

```matlab
reportConfig = mechanics.config.studyReportConfig();
reportConfig.outputFolder = "results/my-study/report";
files = mechanics.io.exportTensileStudyReport(study, reportConfig);
```

The report includes specimen counts, processing status, fracture metrics, selected constitutive models, reproducibility metadata, and links to configured figures.

Standard figure groups are individual specimen curves, the population response, and fracture metrics. Figure groups can be disabled independently.

The report exporter only renders an existing `study` structure. It does not rerun extraction, fitting, fracture analysis, or population statistics.
