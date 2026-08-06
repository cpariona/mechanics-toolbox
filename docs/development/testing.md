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
- plotting and presentation contracts;
- Markdown serialization, exports, and reports;
- end-to-end regression behavior.

`test_plotting_units.m` protects the stored-unit, display-unit, and mechanical-label boundary. It also verifies that label migration does not alter plotted data.

`test_markdown_table_serialization.m` protects the shared scalar Markdown contract, including numeric precision, non-finite values, missing text, logicals, datetime values, scalar cells, escaped pipes, and the retained blank line after a table.

Tests created only to verify a temporary migration or removed compatibility alias should be deleted once the canonical API is covered by functional tests. Test count alone is not a cleanup target; redundant behavior coverage, duplicated fixtures, and unnecessarily repeated expensive workflows are.

## Running focused tests

Calling a function-based test file by name constructs and displays its suite but does not execute the tests:

```matlab
test_joint_mode_plotting
```

A returned `Test` array is therefore not a pass or failure result.

Execute one test file with `runtests`:

```matlab
results = runtests( ...
    "tests/test_joint_mode_plotting.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), "Focused tests failed.")
```

Execute several affected files together:

```matlab
results = runtests([ ...
    "tests/test_plotting_units.m"
    "tests/test_markdown_table_serialization.m"
    "tests/test_joint_mode_plotting.m"
    ], "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), "Focused tests failed.")
```

List discovered tests without executing the complete suite:

```matlab
suite = testsuite("tests", "IncludeSubfolders", true);
disp(string({suite.Name})')
```

## Release validation

Before merging maintenance or release changes, run from the branch intended for merge:

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

Also verify the Git state against the intended base branch:

```bash
git fetch origin --prune
git diff --check origin/main...HEAD
git diff --stat origin/main...HEAD
git status -sb
git ls-files --others --exclude-standard
git ls-files results
```

Review the complete branch diff:

```bash
git diff origin/main...HEAD
git log --oneline origin/main..HEAD
```

The release gate is satisfied only when:

- every discovered MATLAB test passes from the branch intended for merge;
- no test remains incomplete;
- `git diff --check` is clean;
- no unintended generated or untracked files are present;
- no generated files under `results/` are tracked;
- documentation reflects the implemented contracts;
- merge authorization has been given explicitly.

Do not claim MATLAB validation unless the person who ran MATLAB reports the actual result.
