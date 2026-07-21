# Phase 18 — Constitutive fit residual diagnostics

Run the phase-specific tests:

```matlab
results = runtests( ...
    "tests/test_phase18_residual_diagnostics.m", ...
    "IncludeSubfolders", true);

disp(table(results))

assert(all([results.Passed]), ...
    "One or more Phase 18 tests failed.")
```

Then run the complete repository suite:

```matlab
results = run_all_tests();
```

Example:

```matlab
run_fit_residual_diagnostics
```
