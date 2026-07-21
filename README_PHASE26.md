# Phase 26 validation

Run the fracture-maintenance regression tests:

```matlab
results = runtests( ...
    "tests/test_phase12_fracture_analysis.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), ...
    "One or more Phase 26 fracture tests failed.")
```

Then run the complete repository suite:

```matlab
results = run_all_tests();
```

The complete suite is the required release-gate validation for Phase 26.
