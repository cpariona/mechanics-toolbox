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

Before merging maintenance or release changes, run:

```matlab
clear
clc
close all
results = run_all_tests();
```

The release gate is satisfied only when every discovered test passes from the branch intended for merge.
