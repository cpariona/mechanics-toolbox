# Repository structure

## Maintained code

```text
src/+mechanics/
```

This package contains the supported implementation. Public workflows should use namespaced functions such as `mechanics.workflow.*`, `mechanics.fitting.*`, and `mechanics.io.*`.

## User workflows

```text
examples/
```

Examples demonstrate supported APIs. They may use synthetic inputs or require user-supplied experimental workbooks. They are not part of the automated test suite. Examples should represent maintained workflows and must not depend on removed configuration fields or deprecated result columns.

## Regression tests

```text
tests/
```

Test files are named by behavior or subsystem. Tests are maintained source files, not generated output, and should remain versioned even when they cover compatibility behavior.

## Documentation

```text
docs/
```

Documentation is organized by workflow, data handling, technical reference, and repository development.

## Local data and generated output

```text
data/raw/
results/
```

These paths are intentionally ignored by Git. They may exist in a local working copy, but experimental workbooks, MAT files, generated tables, reports, and figures must not be committed. Raw data that must be retained should be archived outside the repository or in an explicitly managed data store.

## Root entrypoints

The maintained MATLAB files at repository root are:

```text
startup.m
run_all_tests.m
```

Implementation belongs under `src/+mechanics`; runnable demonstrations belong under `examples`; tests belong under `tests`. Experiment-specific scripts and unnamespaced processing helpers should not be added at repository root.
