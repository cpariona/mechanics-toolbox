# Phase 16 — Constitutive fit identifiability

Run the phase-specific tests:

```matlab
results = runtests( ...
    "tests/test_phase16_fit_identifiability.m", ...
    "IncludeSubfolders", true);

disp(table(results))

assert(all([results.Passed]), ...
    "One or more Phase 16 tests failed.")
```

Run the full suite:

```matlab
results = run_all_tests();
```

Example:

```matlab
run_fit_identifiability
```
