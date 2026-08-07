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

## Constitutive-model registry boundary

Registered constitutive-model identity, presentation name, family identity, polynomial order when meaningful, parameter names, bounds, default initial guesses, function handles, descriptions, and derived quantities belong to `mechanics.models.modelRegistry`.

The maintained Yeoh family uses one constitutive evaluator:

```text
mechanics.models.yeoh
```

and two explicit registered variants:

```text
yeoh-second-order -> C10, C20
yeoh-third-order  -> C10, C20, C30
```

For both variants:

```text
familyName = yeoh
```

and the registry records:

```text
order = 2   for yeoh-second-order
order = 3   for yeoh-third-order
```

The bare identifier `yeoh` is not a registered model identity. It names the constitutive family and the shared evaluator only. Do not add `yeoh` as an alias for `yeoh-third-order`, and do not create wrappers, bridge files, or duplicate Yeoh evaluators solely to distinguish polynomial order.

Human-facing model names are separate registry metadata:

```text
Yeoh second order
Yeoh third order
```

Persisted model identities in MAT/CSV results use the canonical registered names, not display names:

```text
yeoh-second-order
yeoh-third-order
```

Results generated before this explicit-order migration may contain the historical third-order identifier `yeoh`. Generated `results/` artifacts are reproducible local outputs and are not a compatibility contract for the maintained library. Regenerate them with current drivers when they must be consumed by current workflows; do not add a legacy model alias to accommodate historical generated files.

`mechanics.models.evaluateModel` validates parameter count from registry metadata before calling the evaluator. Fitting, model selection, exporters, plotting, and population workflows should therefore consume registry metadata rather than add model-name conditionals.

For both maintained Yeoh orders, the initial shear modulus is registry-derived as:

```text
mu0 = 2 * C10
```

Population/statistical code must consume the registered derived-quantity contract rather than reimplement this formula by model name.

Library workflow defaults remain independent of the complete list returned by `mechanics.models.listModels`. Registering a model makes it available; it does not automatically add that model to every default candidate set. Experiment-specific drivers may explicitly request additional registered candidates when a scientific comparison is intended.

## Naming boundaries

Use terminology consistently:

- `tension` and `compression` describe constitutive modes or specimen-level mechanics;
- `tensile study` and `compression study` describe experimental workflow families;
- `specimen-level mechanics` processes or evaluates one specimen;
- `study-level workflow` orchestrates a complete campaign;
- `completed-study add-on` consumes canonical completed-study results without re-importing raw data;
- `joint characterization` combines completed experimental modes under one shared constitutive contract;
- `tensile application-range characterization` is a completed-study add-on and does not replace the tensile study.

Preserve existing public names unless a demonstrated ambiguity or ownership defect justifies migration.

## Unit-presentation boundary

Stored physical values and stored units belong to processed results. Human-facing transformations belong to plotting and export contracts.

The maintained responsibilities are:

```text
mechanics.plotting.resolveStudyUnits
    retrieves stored study units from completed study records

mechanics.plotting.mechanicalDisplayUnit
    converts stored units to the display convention for a known physical quantity

mechanics.plotting.mechanicalAxisLabel
    builds standard labels for known mechanical quantities

mechanics.plotting.formatUnitLabel
    appends an already resolved display unit to a specialized or generic label text
```

Current display conventions include:

```text
dimensionless deformation -> mm/mm
normalized quantities -> [-]
stress-like quantities -> stored stress unit
```

`formatUnitLabel` must not infer physical semantics from free-text label content. A caller that uses specialized wording must resolve the display unit explicitly before formatting the label.

A plotter must not invent physical units when its input contract does not retain unit metadata. Extend the producer and result contract first, then migrate the plotter with tests.

## Serialization boundary

`mechanics.io` owns maintained report serialization.

Use:

```text
mechanics.io.writeMarkdownTable
```

only for the established scalar Markdown table contract:

```text
numeric scalars -> %.6g
NaN and infinities -> explicit text
missing text -> missing
logical scalars -> true/false
datetime -> MATLAB string representation
scalar cells -> unwrapped
empty or non-scalar numeric values -> empty cell text
pipe characters -> escaped
blank line after the table
```

Do not force report writers with different behavior for empty tables, missing values, arrays, NaN, or whitespace through this helper. A broader migration requires an intentional canonical contract and direct regression tests.

The shared helper writes only one table to an already open file identifier. It does not open or close files, create report sections, write figures, or act as a report builder.

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
