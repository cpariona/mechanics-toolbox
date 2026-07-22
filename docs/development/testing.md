# Testing

Initialize the repository before focused tests:

```matlab
startup
```

Run the complete suite:

```matlab
results = run_all_tests();
```

The runner discovers every test under `tests/`, includes subfolders, prints a result table, and raises `mechanics:tests:RepositoryTestsFailed` when a test fails or remains incomplete.

Run one test file directly:

```matlab
results = runtests( ...
    "tests/test_curve_segmentation.m", ...
    "IncludeSubfolders", true);

disp(table(results))
assert(all([results.Passed]), "Focused tests failed.")
```

List discovered tests without executing them:

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
