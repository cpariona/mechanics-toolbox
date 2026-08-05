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
- completed-study add-ons such as tensile application-range characterization;
- joint material characterization across completed experimental modes;
- end-to-end workflow orchestration;
- report and export presentation.

A workflow configuration may contain lower-level configuration structs. It does not replace them. For example, `compressionConfig` controls one processed compression curve, while `compressionStudyConfig` coordinates file input, cycle selection, processing, fitting, and export for a complete study.

Retain a configuration function only when it is consumed by maintained implementation, a supported example, an executable study driver, or a behavioral test. A test that only instantiates a configuration is not sufficient evidence by itself.

A completed-study add-on must consume the canonical study result rather than re-importing or reprocessing raw data. It may specialize an existing study to a new analysis contract, but it must not duplicate the study workflow. Tensile application-range characterization is subordinate to the completed tensile study and reuses maintained fitting, model-selection, registry, plotting, and export contracts when they are physically identical.

Joint material characterization must consume completed study results through one explicit workflow contract. Mode-specific extraction belongs in a small registered adapter or mode contract only when the physical data representation differs. Constitutive model evaluation and parameter metadata remain owned by the model registry. Do not scatter tension/compression conditionals across fitting, ranking, export, and plotting code.

Extract a shared lower-level function only when at least two maintained callers use the same physical and data contract. Do not create wrappers, aliases, bridge files, or one-caller helpers for superficial symmetry.

## Package ownership

Use these ownership rules when adding or moving maintained code:

```text
mechanics.analysis       deterministic mechanical calculations
mechanics.config         declarative configuration contracts
mechanics.extraction     workbook-format detection and extraction
mechanics.fitting        optimization and fit-specific diagnostics
mechanics.internal       non-public low-level implementation utilities
mechanics.io             file reading, normalization, serialization, and reports
mechanics.models         constitutive equations and model metadata
mechanics.plotting       figure construction, unit-aware labels, and figure persistence
mechanics.preprocessing  reusable curve preparation
mechanics.quality        specimen-quality assessment
mechanics.segmentation   loading-region and cycle selection
mechanics.statistics     population summaries and statistical inference
mechanics.workflow       orchestration across maintained lower-level contracts
```

Do not move a function solely to make folders visually balanced. Move it only when ownership is incorrect and callers, tests, and documentation support the change.

## Naming boundaries

Use terminology consistently:

- `tension` and `compression` describe constitutive modes or specimen-level mechanics;
- `tensile study` and `compression study` describe experimental workflow families;
- `joint characterization` combines completed experimental modes under one shared constitutive contract;
- `tensile application-range characterization` is a completed-study add-on and does not replace the tensile study.

Preserve existing public names unless a demonstrated ambiguity or ownership defect justifies migration.

## Unit-presentation boundary

Stored physical values and units belong to processed results. Human-facing presentation belongs to plotting and export contracts.

Current display conventions include:

```text
dimensionless strain -> mm/mm
normalized quantities -> [-]
stress-like quantities -> stored stress unit
```

A shared presentation helper should own each convention. Avoid parallel near-duplicate unit transformations in individual plotters or exporters.

## Executable study drivers

```text
studies/
```

Study drivers configure and execute real experimental campaigns. They may define input paths, exclusions, measurement assumptions, fitting settings, optional analyses, output folders, and report configuration.

They are not library implementation and are not simplified demonstrations. Study drivers must call maintained public APIs rather than duplicate reusable processing logic. Organize them by test family or campaign, for example:

```text
studies/tension/run_tensile_experiment.m
studies/tension/run_tensile_application_range_characterization.m
studies/compression/run_compression_experiment.m
studies/joint-characterization/run_joint_material_characterization.m
```

The tensile application-range driver must consume a completed tensile study MAT file or in-memory study result. It must not re-import raw workbooks or reproduce the tensile experiment driver.

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

Completed-study add-on tests should validate source-study contracts, range restriction, shared fitting, model selection, registry-derived quantities, optional external validation, figures, and export without duplicating raw-data workflow tests.

Joint characterization tests should be organized by behavior rather than phase. Synthetic parameter-recovery tests belong in the fitting or workflow test that owns the contract. Real-data validation remains outside committed test fixtures unless an explicitly managed small dataset is later approved.

## Documentation

```text
docs/
```

Documentation is organized by workflow, data handling, technical reference, and repository development.

`docs/development/context-handoff.md` is the only canonical source for current repository state and the next maintenance phase. Historical audits must be labeled as snapshots and must not function as parallel roadmaps.

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

## Organization maintenance rule

A source-organization phase should prioritize contract consolidation over folder reshuffling:

1. inspect all maintained callers;
2. identify genuine duplicate physical or serialization contracts;
3. define one owner;
4. migrate callers with focused tests;
5. remove obsolete helpers only after canonical coverage exists;
6. update documentation in the same phase;
7. run the complete validation gate.
