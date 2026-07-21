# Phase 17 — Constitutive fit-window stability

Run the phase-specific tests:

```matlab
results = runtests( ...
    "tests/test_phase17_fit_window_stability.m", ...
    "IncludeSubfolders", true);

disp(table(results))

assert(all([results.Passed]), ...
    "One or more Phase 17 tests failed.")
```

Then run the complete repository suite:

```matlab
results = run_all_tests();
```

Example:

```matlab
run_fit_window_stability
```
