# Phase 19 validation

Run the focused tests:

```matlab
results = runtests( ...
    "tests/test_phase19_fit_reliability.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), ...
    "One or more Phase 19 tests failed.")
```

Then run the repository suite:

```matlab
results = run_all_tests();
```

Example:

```matlab
run_fit_reliability
```
