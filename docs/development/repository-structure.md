# Repository structure

## Maintained code

```text
src/+mechanics/
```

This package contains the supported implementation. Public workflows should use namespaced functions such as `mechanics.workflow.*`, `mechanics.fitting.*`, and `mechanics.io.*`.

Configuration functions under `mechanics.config` are organized by level:

- specimen-level processing: import, tension, compression, segmentation, and peak analysis;
- fitting and diagnostics: fitting, uncertainty, identifiability, residuals, reliability, window stability, and model selection;
- dataset and population analysis;
- end-to-end workflow orchestration;
- report and export presentation.

A workflow configuration may contain lower-level configuration structs. It does not replace them. For example, `compressionConfig` controls one processed compression curve, while `compressionStudyConfig` coordinates file input, cycle selection, processing, fitting, and export for a complete study.

Retain a configuration function only when it is consumed by maintained implementation, a supported example, or a behavioral test. A test that only instantiates a configuration is not sufficient evidence by itself.

## User workflows

```text
examples/
```

Examples demonstrate supported APIs. They may use synthetic inputs or require user-supplied experimental workbooks. They are not part of the automated test suite. Examples should represent maintained workflows and must not depend on removed configuration fields or result columns.

Keep an example only when it demonstrates a distinct supported entrypoint, configuration pattern, or output. Remove experiment-specific scripts, transitional migration examples, and examples fully duplicated by a clearer end-to-end workflow.

Input templates used by examples belong under:

```text
examples/templates/
```

## Regression tests

```text
tests/
```

Test files are named by behavior or subsystem. Tests are maintained source files, not generated output. Temporary migration tests should be removed after the canonical API has functional coverage; tests should not preserve removed aliases or obsolete contracts.

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
