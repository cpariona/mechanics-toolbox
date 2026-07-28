# Data import and processing

## Single-specimen table import

Supported inputs include `.xlsx`, `.xls`, `.xlsm`, `.csv`, and `.txt` files.

```matlab
config = mechanics.config.excelImportConfig();
specimen = mechanics.io.readSpecimenTable(filename, config);
```

The importer resolves configured aliases for force, displacement, optional time,
and optional current-area columns. Unit conversion is explicit through scale
factors; units are not inferred automatically from headers.

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

`raw.currentArea` is optional. When used, it must contain one positive area value
per force-displacement observation after scaling.

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

The maintained registry includes `zwick-d412` and `generic-table`. The Zwick
entry is retained for compatibility, but the adapter supports both tensile and
compression workbooks that use `Resultados` plus `Probeta` sheets. Extraction
returns a normalized dataset whose specimens contain raw signals, source
metadata, geometry, test type, and processing history.

Geometry is resolved from result-sheet headers rather than fixed columns:

```text
Tension:     h + b    -> initialArea = h*b
Compression: d0 + h0  -> initialArea = pi*d0^2/4, initialLength = h0
```

For tensile workbooks, gauge length must still be supplied when it is absent
from the workbook. For compression workbooks, `h0` defines the initial length.
The extractor reports dimensions but does not decide whether a specimen meets a
particular standard tolerance.

## Manifest input

Manifest input is supported through the maintained study workflows rather than
a separate row-oriented batch processor. Required and optional columns depend on
the selected study contract.

For tension:

```matlab
config = mechanics.config.tensileStudyConfig();
study = mechanics.workflow.runTensileStudy( ...
    "specimen_manifest.xlsx", config);
```

For compression:

```matlab
config = mechanics.config.compressionStudyConfig();
config.input.type = "manifest";
study = mechanics.workflow.runCompressionStudy( ...
    "specimen_manifest.xlsx", config);
```

Manifest rows are normalized before common study analysis. Inclusion flags,
sheet selection, specimen identifiers, and geometry remain explicit inputs. See
`docs/reference/tensile-input-contracts.md` and
`docs/workflows/compression-study.md` for the maintained column contracts.

## Dataset analysis

```matlab
config = mechanics.config.datasetAnalysisConfig();
analysis = mechanics.workflow.analyzeExtractedDataset(dataset, config);
```

Dataset analysis performs quality assessment, segmentation, mechanical
processing, optional constitutive fitting, specimen-level failure isolation,
summaries, plotting, and export. Workbook layout detection remains the
responsibility of the extraction layer.

## Exports

```matlab
mechanics.io.exportSpecimenResults(specimen, outputFolder);
mechanics.io.exportDatasetAnalysis(analysis, outputFolder);
```

Complete study workflows expose their own maintained export and report contracts.
Persistent workflow figures are written as both the configured image format and
an editable MATLAB `.fig` file.

Specimen curve exports include displacement, force, strain, stress, current
area, area scale, tangent modulus, and geometry-uncertainty columns when those
quantities are available.
