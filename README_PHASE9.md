# Phase 9 — Replicate population statistics

Phase 9 aggregates processed specimens into population-level curves, confidence
intervals, scalar summaries, and constitutive-parameter summaries.

## Validation

```matlab
startup
results = runtests("tests/test_phase9_population_analysis.m", ...
    "IncludeSubfolders", true);
disp(table(results))
assert(all([results.Passed]), "One or more Phase 9 tests failed.")
```

## Ecoflex workflow

```matlab
run_ecoflex_population_analysis
```
