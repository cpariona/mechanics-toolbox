# Phase 25 validation

Run the phase-specific tests:

```matlab
results = runtests( ...
    "tests/test_phase25_final_study_report.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), ...
    "One or more Phase 25 tests failed.")
```

Then run the complete repository suite:

```matlab
results = run_all_tests();
```

Example:

```matlab
run_constitutive_study_report
```
