# Phase 20 validation

Run the phase-specific tests:

```matlab
results = runtests( ...
    "tests/test_phase20_fit_diagnostics_workflow.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), ...
    "One or more Phase 20 tests failed.")
```

Then run the complete repository suite:

```matlab
results = run_all_tests();
```

Example:

```matlab
run_fit_diagnostics_workflow
```