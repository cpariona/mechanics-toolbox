# Extracted dataset analysis

Phase 8 connects workbook extraction to reproducible specimen-level analysis.

## Responsibilities

The dataset-analysis layer performs:

1. raw-data quality assessment;
2. mechanical processing;
3. optional hyperelastic fitting and robust model selection;
4. specimen-level failure isolation;
5. consolidated summary and export.

It does not inspect workbook layouts. That remains the responsibility of the
extraction layer.

## Quality criteria

```matlab
config.quality.minimumObservations
config.quality.requireMonotonicDisplacement
config.quality.maximumDisplacementReversalFraction
config.quality.minimumDisplacementRange
config.quality.minimumForceRange
config.quality.maximumNonfiniteFraction
config.quality.rejectFailedQuality
```

A failed quality assessment can either block processing or be retained only as a
reported diagnostic by changing `rejectFailedQuality`.

## Analysis

```matlab
config = mechanics.config.datasetAnalysisConfig();

analysis = mechanics.workflow.analyzeExtractedDataset( ...
    dataset, config);
```

Each specimen record receives one status:

- `processed`;
- `quality-failed`;
- `failed`.

`continueOnError = true` isolates processing failures.

## Optional fitting

```matlab
config.fitting.enabled = true;
config.fitting.modelNames = [
    "neo-hookean"
    "mooney-rivlin"
    "yeoh"
];
```

Model fitting uses the robust deformation-window selection implemented in Phase
4.

## Summary

```matlab
analysis.summary
```

The summary includes quality diagnostics, stress-strain results, tangent modulus,
best eligible model, fit quality, and error information.

## Export

```matlab
mechanics.io.exportDatasetAnalysis(analysis, outputFolder);
```

This creates:

- `dataset_summary.csv`;
- `dataset_analysis.mat`.
