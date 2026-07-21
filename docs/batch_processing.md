# Batch processing

Phase 6 adds manifest-driven processing for multiple mechanical-test specimens.

## Required manifest columns

- `File`
- `SpecimenId`
- `InitialLength`
- `InitialArea`

## Optional columns

- `Include`
- `Sheet`
- `ForceScale`
- `DisplacementScale`
- `TimeScale`
- `ForceColumn`
- `DisplacementColumn`
- `TimeColumn`
- `TestType`

`TestType` accepts `tension` or `compression`. Sign conventions remain explicit
through `ForceScale` and `DisplacementScale`; for example, use `-1` when an
instrument exports compression as negative but positive compression is desired.

## Processing

```matlab
config = mechanics.config.batchProcessingConfig();

batch = mechanics.workflow.processBatchManifest( ...
    "specimen_manifest.xlsx", config);
```

The returned structure contains:

```text
batch.manifest
batch.records
batch.summary
batch.config
batch.createdAt
```

Every row is reported as:

- `processed`;
- `failed`;
- `skipped`.

When `continueOnError` is true, one invalid specimen does not stop the complete
batch.

## Optional fitting

```matlab
config.fitting.enabled = true;
config.fitting.modelNames = [
    "neo-hookean"
    "mooney-rivlin"
    "yeoh"
];
```

The best eligible model is included in `batch.summary.BestModel`.

## Export

```matlab
mechanics.io.exportBatchSummary(batch, "results/batch-01");
```

This creates:

- `batch_summary.csv`;
- `batch_results.mat`.
