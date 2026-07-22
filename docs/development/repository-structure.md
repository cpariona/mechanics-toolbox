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

Examples demonstrate supported APIs. They may use synthetic inputs or require user-supplied experimental workbooks. They are not part of the automated test suite.

## Regression tests

```text
tests/
```

Test files are named by behavior or subsystem.

## Documentation

```text
docs/
```

Documentation is organized by workflow, data handling, technical reference, and repository development.

## Root entrypoints

The maintained MATLAB files at repository root are:

```text
startup.m
run_all_tests.m
```

Implementation belongs under `src/+mechanics`; runnable demonstrations belong under `examples`; tests belong under `tests`. Experiment-specific scripts and unnamespaced processing helpers should not be added at repository root.
