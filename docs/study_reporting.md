# Tensile study reporting

Phase 14 exports standard study figures and a Markdown report from a completed
`tensileStudy` structure.

```matlab
config = mechanics.config.studyReportConfig();
config.outputFolder = "results/ecoflex-0050/report";

files = mechanics.io.exportTensileStudyReport(study, config);
```

The report includes:

- study-level specimen counts;
- specimen processing status;
- peak force and peak displacement;
- selected constitutive model;
- reproducibility metadata;
- links to exported figures.

Standard figures are:

```text
individual_curves.png
population_curve.png
fracture_metrics.png
```

Figure groups can be disabled independently:

```matlab
config.includeIndividualCurves = true;
config.includePopulationCurve = false;
config.includeFractureMetrics = true;
```

The report exporter does not rerun extraction, fitting, fracture analysis, or
population statistics. It only renders an already completed study.
