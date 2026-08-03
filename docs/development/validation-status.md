# Validation status

## Tensile application-range D1

Branch:

```text
feature/tensile-application-range-contracts
```

The user reported successful execution of:

```text
tests/test_tensile_application_range_input_contract.m
run_all_tests()
```

The D1 implementation validates and normalizes a completed tensile-study result inside a configured interval. It does not implement fitting, selection, sensitivity analysis, optional compression validation, plotting, export, or a study driver.

The validated configuration uses:

```matlab
config.deformationMeasure = "engineering-strain";
config.fitRange = [0, 0.30];
```

Two defects were found and corrected during local validation:

1. table-summary variables are forced to column orientation;
2. range tests do not assume that a sampled grid contains the requested boundary exactly.

Before merge, also verify locally:

```bash
git diff --check
git status -sb
git ls-files --others --exclude-standard
```
