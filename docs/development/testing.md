# Testing

Initialize the repository before running focused tests:

```matlab
startup
```

`startup` adds the repository root and maintained subfolders to the MATLAB path. This allows individual test setup functions to resolve the root entrypoint even when the test runner temporarily changes the working directory.

Run the complete suite:

```matlab
results = run_all_tests();
```

The runner discovers every test under `tests/`, includes subfolders, prints a result table, and raises `mechanics:tests:RepositoryTestsFailed` when any test fails or remains incomplete.

## Test organization

Test files are grouped by subsystem or workflow rather than by implementation phase. Important boundaries include:

- low-level mechanics and constitutive models;
- import, extraction, and unit normalization;
- curve segmentation and quality assessment;
- fitting, diagnostics, uncertainty, and model selection;
- tensile and compression workflows;
- population and group analysis;
- exports and reports;
- end-to-end regression behavior.

`test_measurement_monte_carlo.m` covers measurement-uncertainty propagation through constitutive refitting. `test_compression_population.m` covers compression fitting, default calibrated length, population aggregation, and group comparison. Keeping these concerns separate makes failures easier to localize.

Tests created only to verify a temporary migration or removed compatibility alias should be deleted once the canonical API is covered by functional tests. Test count alone is not a cleanup target; redundant behavior coverage, duplicated fixtures, and unnecessarily repeated expensive workflows are.

Run one test file directly:

```matlab
results = runtests( ...
    "tests/test_curve_segmentation.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), "Focused tests failed.")
```

List discovered tests without executing the complete suite:

```matlab
suite = testsuite("tests", "IncludeSubfolders", true);
disp(string({suite.Name})')
```

## Release validation

Before merging maintenance or release changes, run:

```matlab
restoredefaultpath
clear classes
clear functions
clear
clc
close all

cd("<repository-folder>")
startup
results = run_all_tests();
assert(all([results.Passed]), "Repository tests failed.")
```

Also verify the Git worktree:

```bash
git diff --check
git status -sb
git ls-files --others --exclude-standard
```

The release gate is satisfied only when every discovered test passes from the branch intended for merge and no unintended generated files are tracked.
