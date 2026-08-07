# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

## Current merged baseline

The presentation-contract and Markdown-serialization maintenance phase was merged through PR #51.

PR #51 merge commit:

```text
c021ea4f3d3d00f1d345e779aa3ca2efef411bf4
```

`main` subsequently advanced with documentation-only handoff maintenance. Future sessions must resolve the live `main` and `origin/main` SHAs with Git rather than treating the merge commit above as the permanent branch head.

The maintenance branch `maintenance/consolidate-presentation-contracts` is no longer active. Future implementation should start from updated `main` unless the user explicitly requests otherwise.

## Completed maintenance implementation

### Unit presentation

Stored physical values are not rescaled for presentation.

Responsibilities are separated as follows:

```text
mechanics.plotting.resolveStudyUnits
    retrieves stored study units and canonicalizes dimensionless strain metadata to "-"

mechanics.plotting.mechanicalDisplayUnit
    converts stored units to human-facing display units

mechanics.plotting.mechanicalAxisLabel
    constructs standard labels for known mechanical quantities

mechanics.plotting.formatUnitLabel
    appends an already resolved display unit to a specialized or generic label
```

Human-facing conventions remain:

```text
dimensionless deformation -> mm/mm
stress and stress-like quantities -> stored stress unit
normalized quantities -> [-]
```

`formatUnitLabel` no longer infers strain semantics from free-text labels.

Migrated maintained consumers include:

```text
src/+mechanics/+plotting/plotStressStrain.m
src/+mechanics/+plotting/exportTensileStudyFigures.m
src/+mechanics/+plotting/exportCompressionStudyFigures.m
src/+mechanics/+plotting/plotFittingAudit.m
```

The migration preserves numerical arrays, compression sign conventions, styles, output filenames, and specialized labels.

`plotModelFit` remains intentionally unchanged because its current `fitResult` contract does not retain sufficient unit and measure metadata. Do not add inferred defaults such as `MPa` or `mm/mm` without first extending and validating the result contract.

### Markdown table serialization

A shared serializer owns the identical Markdown table contract used by three maintained exporters:

```text
mechanics.io.writeMarkdownTable
```

Migrated consumers:

```text
src/+mechanics/+io/exportJointMaterialCharacterization.m
src/+mechanics/+io/exportTensileApplicationRangeCharacterization.m
src/+mechanics/+io/exportTensileStudyComparison.m
```

The retained contract includes:

```text
numeric scalars -> %.6g
NaN -> NaN
Inf/-Inf -> Inf/-Inf
missing text -> missing
logical scalars -> true/false
datetime -> MATLAB string representation
scalar cell values -> unwrapped
non-scalar or empty numeric values -> empty cell text
pipe characters -> escaped as \|
blank line after each table
```

Other report writers were not migrated because their contracts differ for empty tables, missing values, arrays, NaN, or trailing whitespace:

```text
exportCompressionStudyReport
exportConstitutiveStudyReport
exportTensileStudyReport
writeFittingAuditSection
```

Do not force them through the shared helper without first defining and testing an intentional canonical migration.

## Validation evidence

The user reported successful local MATLAB execution after PR #51 was merged:

```text
tests/test_plotting_units.m
tests/test_markdown_table_serialization.m
run_all_tests()
```

The complete repository suite passed locally on the merged state. This evidence was reported by the user; MATLAB was not executed by the assistant.

## Tests added or extended

```text
tests/test_plotting_units.m
tests/test_markdown_table_serialization.m
```

The plotting tests protect stored-versus-display unit ownership, semantic labels, fitting-audit units, and preservation of plotted data.

The Markdown tests protect scalar formatting, missing and non-finite values, logicals, datetime values, scalar cells, pipe escaping, and the retained blank line after a table.

## Package ownership findings

No package moves were justified in the completed maintenance phase.

The inspected functions remain correctly owned:

```text
mechanics.plotting
    figure construction and human-facing unit presentation

mechanics.io
    report serialization and Markdown table output
```

The phase prioritized contract consolidation rather than cosmetic folder reorganization.

## Terminology boundaries

Use these terms consistently:

- `tension` and `compression` describe constitutive modes or specimen-level mechanics;
- `tensile study` and `compression study` describe complete experimental workflow families;
- `specimen-level mechanics` processes or evaluates one specimen;
- `study-level workflow` orchestrates a complete campaign;
- `completed-study add-on` consumes canonical completed-study results without re-importing raw data;
- `joint characterization` combines completed experimental modes under one shared constitutive contract;
- `tensile application-range characterization` is a completed-study add-on and does not replace the tensile study.

Preserve existing public names unless a demonstrated ambiguity or ownership defect justifies migration.

## Next planned phase

The next requested feature is support for a second-order Yeoh constitutive model as an additional fitting candidate.

This feature has not yet been implemented. Before modifying code:

1. inspect the current model registry and existing Yeoh implementation;
2. define the exact constitutive equation and parameter naming for the second-order form;
3. determine whether it should be a distinct registered model or an order-parameterized implementation without changing public behavior of the current Yeoh model;
4. inspect fitting, model-selection, reporting, plotting, and application-range callers for hard-coded model-name or parameter-count assumptions;
5. add the smallest registry-driven implementation and focused tests before enabling it in workflow defaults.

The new model must not change the equations, parameter identities, ranking behavior, defaults, or stored results of existing Neo-Hookean, Mooney-Rivlin, or current Yeoh fits unless explicitly approved.

## Required architecture contracts

- Favor simplicity, structure, order, and explicit ownership.
- Keep reusable implementation under `src/+mechanics`.
- Keep real experiment drivers under `studies`.
- Keep runnable demonstrations under `examples` and regression coverage under `tests`.
- Do not add implementation at repository root; maintained root MATLAB entrypoints are `startup.m` and `run_all_tests.m`.
- Extract shared code only when at least two maintained callers use the same physical and data contract.
- Do not create wrappers, aliases, bridge files, or one-caller helpers for superficial symmetry.
- Do not reorganize packages merely because a folder has many files.
- Preserve public APIs unless a demonstrated structural defect justifies migration.
- Use the model registry rather than scattering model-name conditionals when the contracts are identical.
- Keep model evaluation in `mechanics.models`, optimization in `mechanics.fitting`, population inference in `mechanics.statistics`, deterministic mechanical calculations in `mechanics.analysis`, and orchestration in `mechanics.workflow`.
- Keep individual tensile, compression, joint-characterization, and tensile application-range workflows distinct.
- Preserve completed-study add-ons as consumers of canonical completed study results; do not re-import or reprocess raw data.
- Preserve stored physical values and signs. Presentation conventions must not silently change numerical state.
- Generated data and outputs remain under ignored `results/` paths.
- Do not merge a pull request unless explicitly requested.

## Efficiency requirements

- Inspect callers before extracting, moving, or deleting a function.
- Prefer one small shared contract over parallel near-duplicates.
- Avoid broad rewrites when a localized consolidation is sufficient.
- Keep tests focused by subsystem and avoid repeating expensive end-to-end workflows unnecessarily.
- Do not retain obsolete migration tests after canonical behavioral coverage exists.
- Update canonical documentation in the same phase as structural changes.

## Session bootstrap

Before proposing or modifying code in a new session:

1. read this file completely;
2. read `docs/development/repository-structure.md`;
3. read the relevant workflow and testing documents;
4. verify Git state:

```bash
git fetch origin --prune
git switch main
git pull --ff-only origin main
git status -sb
git rev-parse HEAD
git rev-parse origin/main
```

5. create a dedicated branch for code changes unless the user explicitly requests direct work on `main`;
6. inspect current callers and tests before proposing moves or shared helpers;
7. define the smallest coherent phase and its validation gate before implementation.
