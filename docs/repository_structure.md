# Repository structure

## Maintained code

```text
src/+mechanics/
```

This package contains the supported implementation. Public workflows should use
namespaced functions such as `mechanics.workflow.*`, `mechanics.fitting.*`, and
`mechanics.io.*`.

## User workflows

```text
examples/
```

Examples demonstrate supported APIs. They may use synthetic inputs or require
user-supplied experimental workbooks. They are not part of the automated test
suite.

## Regression tests

```text
tests/
```

Test files are named by behavior or subsystem. Historical development-phase
identifiers are intentionally excluded from filenames.

## Documentation

```text
docs/
```

Documentation is organized by scientific capability and workflow. Temporary
phase scopes and phase-specific validation readmes are not maintained.

## Root entrypoints

The maintained MATLAB files at repository root are:

```text
startup.m
run_all_tests.m
```

Legacy unnamespaced processing helpers and experiment-specific scripts should not
be reintroduced at repository root. New implementation belongs under
`src/+mechanics`; runnable demonstrations belong under `examples`; tests belong
under `tests`.
