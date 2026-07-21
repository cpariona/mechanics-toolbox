# Phase 22 validation

Run the phase-specific tests:

```matlab
results = runtests( ...
    "tests/test_phase22_batch_model_comparison.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), ...
    "One or more Phase 22 tests failed.")
```

Then run the complete repository suite:

```matlab
results = run_all_tests();
```

Example:

```matlab
run_batch_model_comparison
```
