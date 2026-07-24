# Data import and processing

## Single-specimen table import

Supported inputs include `.xlsx`, `.xls`, `.xlsm`, `.csv`, and `.txt` files.

```matlab
config = mechanics.config.excelImportConfig();
specimen = mechanics.io.readSpecimenTable(filename, config);
```

The importer resolves configured aliases for force, displacement, optional time, and optional current-area columns. Unit conversion is explicit through scale factors; units are not inferred automatically from headers.

For measured current area:

```matlab
config.currentAreaColumns = ["CurrentArea", "Area_mm2"];
config.currentAreaScale = 1;
```

The normalized specimen contract preserves raw values:

```text
specimen.id
specimen.source
specimen.raw.force
specimen.raw.displacement
specimen.raw.time
specimen.raw.currentArea
specimen.raw.originalTable
specimen.processingHistory
```

`raw.currentArea` is optional. When used, it must contain one positive area value per force-displacement observation after scaling.

Mechanical processing creates derived fields without overwriting `specimen.raw`:

```matlab
config = mechanics.config.tensionConfig();
config.mechanics.stressMeasure = "true";
config.mechanics.areaEvolution = "measured-area";

specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, config);
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

Specimen curve exports include displacement, force, strain, stress, current area, area scale, tangent modulus, and geometry-uncertainty columns when those quantities are available.
