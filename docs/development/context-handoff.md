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

## Active branch

The current feature branch is:

```text
feature/yeoh-second-order
```

It was created from the then-current `main` baseline:

```text
a5dbe4ce27c0472becdb8e90b09c3a6a5690aa5c
```

Do not merge this branch without explicit user authorization.

## Second-order Yeoh feature status

### Maintained naming

The registry now exposes:

```text
neo-hookean
mooney-rivlin
yeoh-second-order
yeoh
```

The unqualified registered name `yeoh` intentionally retains the historical third-order contract.

```text
yeoh-second-order -> C10, C20
yeoh              -> C10, C20, C30
```

No wrapper, alias, bridge file, or duplicate Yeoh evaluator was introduced.

### Constitutive evaluator

`mechanics.models.yeoh` is the single evaluator for the Yeoh family. It accepts exactly two or three parameters:

```text
[C10, C20]       -> second-order Yeoh
[C10, C20, C30]  -> third-order Yeoh
```

The third-order expression is numerically unchanged from the previous maintained implementation.

For both registered Yeoh orders:

```text
mu0 = 2 * C10
```

The derived quantity is owned by registry metadata.

### Registry and fitting integration

`mechanics.models.modelRegistry("yeoh-second-order")` defines:

```text
parameterNames      = C10, C20
defaultInitialGuess = [1, 0]
lowerBounds         = [0, -Inf]
upperBounds         = [Inf, Inf]
derivedQuantity     = mu0
```

Existing fitting and selection implementations required no model-specific production changes. They already consume registry metadata for parameter count, bounds, initial guesses, evaluation, and parsimony.

Validated paths include:

```text
mechanics.fitting.fitModel
mechanics.fitting.fitTensileApplicationRangeModel
mechanics.fitting.fitJointModel
mechanics.workflow.selectTensileApplicationRangeModel
mechanics.workflow.selectJointModel
```

### Population and downstream integration

One hard-coded downstream contract was found in:

```text
mechanics.statistics.deriveInitialShearModulus
```

It previously used a model-name switch for Neo-Hookean, Mooney-Rivlin, and third-order Yeoh. It now obtains `mu0` from registry metadata and reconstructs the registered parameter vector from the selected-parameter table.

The existing statistical error contract for unsupported models remains preserved.

Downstream synthetic coverage now includes:

```text
selected-parameter population
consensus-model fitting
parameter plotting
CSV export
MAT persistence
tensile application-range report/figures/export
joint characterization report/figures/export
```

### Library defaults

Registering `yeoh-second-order` does not add it to every default candidate set.

The library defaults for joint characterization and tensile application-range characterization remain:

```text
neo-hookean
mooney-rivlin
yeoh
```

Changing defaults is explicitly deferred until real-data evidence is reviewed.

### Real-study drivers

The maintained real drivers on the feature branch explicitly compare all four candidates:

```text
neo-hookean
mooney-rivlin
yeoh-second-order
yeoh
```

Affected drivers:

```text
studies/tension/run_tensile_experiment.m
studies/compression/run_compression_experiment.m
studies/tension/run_tensile_application_range_characterization.m
studies/joint-characterization/run_joint_material_characterization.m
```

This is an experiment-specific comparison decision and does not change library defaults.

## Validation evidence

The user reported successful local MATLAB execution after each completed implementation phase.

Validated focused coverage includes:

```text
tests/test_constitutive_models.m
tests/test_tensile_application_range_fitting.m
tests/test_tensile_application_range_selection.m
tests/test_tensile_application_range_workflow.m
tests/test_joint_fixed_model_fitting.m
tests/test_joint_model_selection.m
tests/test_joint_material_characterization_workflow.m
tests/test_selected_parameter_population.m
```

The user also reported that the complete:

```matlab
run_all_tests()
```

suite passed after the mathematical, registry, fitting/selection, and downstream-output phases.

This MATLAB evidence was reported by the user; MATLAB was not executed by the assistant.

## Pending real-data validation

The current real-study result files under ignored `results/` were generated before `yeoh-second-order` was added to the maintained real-driver candidate sets unless the user explicitly regenerates them after this handoff.

Historical results therefore remain evidence for the previous three-model candidate set only.

The next validation step is to regenerate and review, in this order:

```text
1. real tensile study
2. real compression study
3. tensile application-range characterization
4. joint material characterization and robustness audit
```

Review should compare at minimum:

```text
selected model
candidate objective / RMSE / BIC evidence
parameter count
C10, C20, and C30 where applicable
mu0
fitting-window or application-range stability
joint tension/compression fit quality
robustness scenario model identity
```

Do not update scientific conclusions or library defaults before these real results are inspected.

## Completed presentation and serialization contracts

Stored physical values are not rescaled for presentation.

Maintained unit responsibilities remain:

```text
mechanics.plotting.resolveStudyUnits
mechanics.plotting.mechanicalDisplayUnit
mechanics.plotting.mechanicalAxisLabel
mechanics.plotting.formatUnitLabel
```

Human-facing conventions remain:

```text
dimensionless deformation -> mm/mm
stress and stress-like quantities -> stored stress unit
normalized quantities -> [-]
```

`mechanics.io.writeMarkdownTable` remains the shared scalar Markdown serializer for the maintained equivalent table family. Report writers with distinct serialization contracts remain separate.

`plotModelFit` remains intentionally unchanged because its current result contract does not retain sufficient unit and measure metadata. Do not infer physical units there without first extending and validating the producer/result contract.

## Terminology boundaries

- `tension` and `compression` describe constitutive modes or specimen-level mechanics;
- `tensile study` and `compression study` describe complete experimental workflow families;
- `specimen-level mechanics` processes or evaluates one specimen;
- `study-level workflow` orchestrates a complete campaign;
- `completed-study add-on` consumes canonical completed-study results without re-importing raw data;
- `joint characterization` combines completed experimental modes under one shared constitutive contract;
- `tensile application-range characterization` is a completed-study add-on and does not replace the tensile study.

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
