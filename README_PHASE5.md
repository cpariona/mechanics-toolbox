# Phase 5 — Experimental data integration

Phase 5 adds configurable table import, stable specimen processing, provenance,
export, and comparison against legacy curves.

## Validation

```matlab
startup
results = runtests("tests/test_phase5_experimental_io.m", ...
    "IncludeSubfolders", true);
disp(table(results))
assert(all([results.Passed]), "One or more Phase 5 tests failed.")
```

## Main API

```matlab
importConfig = mechanics.config.excelImportConfig();
specimen = mechanics.io.readSpecimenTable(filename, importConfig);

processingConfig = mechanics.config.tensionConfig();
specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, processingConfig);
```

## Examples

```matlab
run_experimental_specimen
run_legacy_curve_comparison
```
