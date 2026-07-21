# Phase 24 validation

Run the phase-specific tests:

```matlab
results = runtests( ...
    "tests/test_phase24_group_parameter_inference.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), ...
    "One or more Phase 24 tests failed.")
```

Then run the complete repository suite:

```matlab
results = run_all_tests();
```

Example:

```matlab
run_group_parameter_inference
```
