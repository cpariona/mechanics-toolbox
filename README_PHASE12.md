# Phase 12 — Tensile fracture metrics

```matlab
startup
results = runtests("tests/test_phase12_fracture_analysis.m", ...
    "IncludeSubfolders", true);
disp(table(results))
assert(all([results.Passed]), "One or more Phase 12 tests failed.")
```

Ecoflex example:

```matlab
run_ecoflex_fracture_analysis
```
