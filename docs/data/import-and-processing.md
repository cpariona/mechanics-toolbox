# Data import and processing

## Single-specimen table import

Supported inputs include `.xlsx`, `.xls`, `.xlsm`, `.csv`, and `.txt` files.

```matlab
config = mechanics.config.excelImportConfig();
specimen = mechanics.io.readSpecimenTable(filename, config);
```

The importer resolves configured aliases for force, displacement, and optional time columns. Unit conversion is explicit through scale factors; units are not inferred automatically from headers.

The normalized specimen contract preserves raw values:

```text
specimen.id
specimen.source
specimen.raw.force
specimen.raw.displacement
specimen.raw.time
specimen.raw.originalTable
specimen.processingHistory
```

Mechanical processing creates derived fields without overwriting `specimen.raw`:

```matlab
specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, mechanics.config.tensionConfig());
```

## Workbook extraction

Vendor-specific extraction is separated from mechanics calculations.

```matlab
config = mechanics.config.workbookExtractionConfig();
config.defaultInitialLength = 25;
dataset = mechanics.extraction.extractWorkbook(filename, config);
```

The maintained registry includes `zwick-d412` and `generic-table`. Extraction returns a normalized dataset whose specimens contain raw signals, source metadata, geometry, and processing history.

The Zwick D412 adapter expects a configurable results sheet and specimen sheets. Gauge length must be supplied when it is absent from the workbook.

## Batch manifests

Manifest-driven processing requires:

```text
File
SpecimenId
InitialLength
InitialArea
```

Optional columns configure inclusion, sheet selection, signal scaling, column names, time, and test type.

```matlab
config = mechanics.config.batchProcessingConfig();
batch = mechanics.workflow.processBatchManifest( ...
    "specimen_manifest.xlsx", config);
```

Rows are reported as `processed`, `failed`, or `skipped`. With `continueOnError = true`, one invalid specimen does not stop the batch.

## Dataset analysis

```matlab
config = mechanics.config.datasetAnalysisConfig();
analysis = mechanics.workflow.analyzeExtractedDataset(dataset, config);
```

Dataset analysis performs quality assessment, segmentation, mechanical processing, optional constitutive fitting, specimen-level failure isolation, summaries, plotting, and export. Workbook layout detection remains the responsibility of the extraction layer.

## Exports

```matlab
mechanics.io.exportSpecimenResults(specimen, outputFolder);
mechanics.io.exportBatchSummary(batch, outputFolder);
mechanics.io.exportDatasetAnalysis(analysis, outputFolder);
```
