# Phase 23 validation

Run the phase-specific tests:

```matlab
results = runtests( ...
    "tests/test_phase23_selected_parameter_population.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), ...
    "One or more Phase 23 tests failed.")
```

Then run the complete repository suite:

```matlab
results = run_all_tests();
```

Example:

```matlab
run_selected_parameter_population
```
