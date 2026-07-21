# Batch reliability-aware model comparison

Phase 22 applies the Phase 21 model-comparison workflow independently to multiple specimens.

Each specimen must provide:

- `specimenId`;
- `deformation`;
- `measuredStress`;
- optional `group`;
- optional `context`.

```matlab
config = mechanics.config.batchModelComparisonConfig();
batch = mechanics.workflow.compareModelsAcrossSpecimens( ...
    specimens, modelNames, fitConfig, config);
```

The result contains specimen-level outcomes, model-selection frequencies, optional group-level frequencies, and the complete comparison object for every successful specimen.

Main outputs:

- `batch.specimenSummary`;
- `batch.modelSummary`;
- `batch.groupSummary`;
- `batch.comparisons`.

A failed specimen can be recorded without stopping the remaining batch when `continueOnSpecimenError` is true.

Export:

```matlab
mechanics.io.exportBatchModelComparison( ...
    batch, "results/batch-model-comparison");
```

The aggregate selection frequency is descriptive. It does not replace specimen-level review or inferential statistics between groups.
