# Phase 8 — Dataset quality and constitutive analysis

Phase 8 adds quality assessment, isolated specimen processing, optional fitting,
dataset summaries, plotting, and export.

## Validation

```matlab
startup
results = runtests("tests/test_phase8_dataset_analysis.m", ...
    "IncludeSubfolders", true);
disp(table(results))
assert(all([results.Passed]), "One or more Phase 8 tests failed.")
```

## Ecoflex example

```matlab
run_ecoflex_dataset_analysis
```

The example requires the original workbook under `data/raw` and the actual gauge
length used in the tensile experiment.
