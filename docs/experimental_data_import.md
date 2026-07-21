# Experimental data import

Phase 5 introduces a configurable adapter between external table files and the
stable specimen contract.

## Supported files

- `.xlsx`, `.xls`, `.xlsm`;
- `.csv`;
- `.txt`.

## Import contract

```matlab
specimen = mechanics.io.readSpecimenTable(filename, importConfig);
```

The returned structure contains:

```text
specimen.id
specimen.source
specimen.raw.force
specimen.raw.displacement
specimen.raw.time              optional
specimen.raw.originalTable
specimen.processingHistory
```

Raw values are never overwritten.

## Column aliases

Column names are resolved first by exact matching and then by normalized
matching. Normalization removes spaces, punctuation, underscores and differences
in capitalization.

Aliases are configured explicitly:

```matlab
config.forceColumns = ["Force_N", "Force", "Load_N"];
config.displacementColumns = ["Displacement_mm", "Extension_mm"];
```

## Unit conversion

Import scaling is explicit:

```matlab
config.forceScale = 1e-3;
config.displacementScale = 1;
```

The importer does not infer physical units from the header.

## Stable processing workflow

```matlab
specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, processingConfig);
```

This preserves raw data and creates:

```text
specimen.processed
specimen.analysis
specimen.geometry
specimen.processingConfig
```

## Legacy comparison

Before deleting old scripts, compare their stress-strain output against the new
pipeline:

```matlab
comparison = mechanics.validation.compareCurves( ...
    legacyCurve, newCurve, tolerance);
```

The comparison interpolates the candidate curve over the reference strain grid
within their common interval and reports normalized RMSE.
