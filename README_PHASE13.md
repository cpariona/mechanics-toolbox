# Phase 13 — Reproducible tensile-study workflow

Run:

```matlab
results = runtests( ...
    "tests/test_phase13_tensile_study.m", ...
    "IncludeSubfolders", true);

disp(table(results))

assert(all([results.Passed]), ...
    "One or more Phase 13 tests failed.")
```

Full suite:

```matlab
results = run_all_tests();
```

Ecoflex:

```matlab
run_ecoflex_tensile_study
```
