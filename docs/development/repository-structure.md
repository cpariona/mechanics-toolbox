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
- joint material characterization across completed experimental modes;
- end-to-end workflow orchestration;
- report and export presentation.

A workflow configuration may contain lower-level configuration structs. It does not replace them. For example, `compressionConfig` controls one processed compression curve, while `compressionStudyConfig` coordinates file input, cycle selection, processing, fitting, and export for a complete study.

Retain a configuration function only when it is consumed by maintained implementation, a supported example, an executable study driver, or a behavioral test. A test that only instantiates a configuration is not sufficient evidence by itself.

Joint material characterization must consume completed study results through one explicit workflow contract. Mode-specific extraction belongs in a small registered adapter or mode contract only when the physical data representation differs. Constitutive model evaluation and parameter metadata remain owned by the model registry. Do not scatter tension/compression conditionals across fitting, ranking, export, and plotting code.

## Executable study drivers

```text
studies/
```

Study drivers configure and execute real experimental campaigns. They may define input paths, exclusions, measurement assumptions, fitting settings, optional analyses, output folders, and report configuration.

They are not library implementation and are not simplified demonstrations. Study drivers must call maintained public APIs rather than duplicate reusable processing logic. Organize them by test family or campaign, for example:

```text
studies/tension/run_tensile_experiment.m
studies/compression/run_compression_experiment.m
studies/joint-characterization/run_joint_material_characterization.m
```

The joint-characterization driver consumes completed tensile and compression study MAT files or in-memory study results. It must not re-import raw workbooks or duplicate the individual study drivers. Future additional modes should be added only after a maintained mode contract exists.

Experiment-specific raw data and generated results remain under ignored `data/` and `results/` paths.

## User examples

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

Joint characterization tests should be organized by behavior rather than phase. Synthetic parameter-recovery tests belong in the fitting or workflow test that owns the contract. Real-data validation remains outside committed test fixtures unless an explicitly managed small dataset is later approved.

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

Implementation belongs under `src/+mechanics`; executable experiment configurations belong under `studies`; runnable demonstrations belong under `examples`; tests belong under `tests`. Experiment-specific scripts and unnamespaced processing helpers should not be added at repository root.
