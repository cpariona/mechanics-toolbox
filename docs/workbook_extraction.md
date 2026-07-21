# Workbook extraction architecture

Phase 7 separates vendor-specific data extraction from mechanical processing.

## Pipeline

```text
original workbook
    ↓
extractor
    ↓
normalized dataset
    ↓
mechanical processing
    ↓
fitting and model selection
```

Processing functions do not inspect workbook layouts. Extractors do not compute
stress, strain, modulus, or constitutive parameters.

## Public API

```matlab
config = mechanics.config.workbookExtractionConfig();
dataset = mechanics.extraction.extractWorkbook(filename, config);
```

## Registered extractors

```matlab
mechanics.extraction.listExtractors()
```

Initial extractors:

- `zwick-d412`;
- `generic-table`.

`extractor = "auto"` selects the first registered extractor whose detector
recognizes the workbook.

## Zwick/Roell D412 extractor

The initial Zwick extractor supports workbooks with:

- one `Resultados` sheet;
- specimen sheets matching `^Probeta\s+\d+$`;
- column names in a configurable row;
- units in a configurable row;
- data beginning in a configurable row;
- thickness and width stored in `Resultados`.

The default layout is:

```text
specimen sheet row 1: sheet title
specimen sheet row 2: variable names
specimen sheet row 3: units
specimen sheet row 4: first observation
```

All row numbers, sheet names, patterns, aliases, and metadata column indices are
configuration values.

## Normalized dataset contract

```text
dataset.source
dataset.extractor
dataset.metadata
dataset.specimens
```

Each specimen contains:

```text
specimen.id
specimen.sheetName
specimen.testType
specimen.raw.force
specimen.raw.displacement
specimen.geometry.initialLength
specimen.geometry.thickness
specimen.geometry.width
specimen.geometry.initialArea
specimen.source
specimen.metadata
specimen.processingHistory
```

The extractor preserves force and displacement in the units reported by the
workbook.

## Gauge length

The supplied workbook contains thickness and width but does not explicitly
provide the tensile gauge length used to calculate engineering strain.

Set it explicitly:

```matlab
config.defaultInitialLength = 25;
```

If it remains undefined, extraction succeeds but mechanical processing raises
`mechanics:workflow:MissingInitialLength`.

## Custom extractors

A custom extractor can be injected without changing the registry:

```matlab
config.customExtractor = @myExtractor;
dataset = mechanics.extraction.extractWorkbook(filename, config);
```

The custom function must have this signature:

```matlab
dataset = myExtractor(filename, config)
```

and return the normalized dataset contract.
