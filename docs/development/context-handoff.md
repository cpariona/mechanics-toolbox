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

## Yeoh family feature status

### Final registered naming contract

The registry exposes these constitutive model identities:

```text
neo-hookean
mooney-rivlin
yeoh-second-order
yeoh-third-order
```

The Yeoh variants are explicit and symmetric:

```text
yeoh-second-order -> C10, C20       -> order 2
yeoh-third-order  -> C10, C20, C30  -> order 3
```

Both variants share:

```text
familyName     = yeoh
functionHandle = mechanics.models.yeoh
mu0            = 2 * C10
```

Human-facing names are registry metadata:

```text
Yeoh second order
Yeoh third order
```

The bare identifier `yeoh` is not a registered model identity and is not retained as a compatibility alias. It names only the constitutive family and the single maintained evaluator `mechanics.models.yeoh`.

No wrapper, alias, bridge file, duplicate evaluator, or model-specific fitting path was introduced.

### Constitutive evaluator

`mechanics.models.yeoh` remains the single evaluator for the Yeoh family. It accepts exactly two or three parameters:

```text
[C10, C20]       -> second-order Yeoh
[C10, C20, C30]  -> third-order Yeoh
```

The third-order constitutive expression is numerically unchanged from the pre-feature implementation.

### Registry metadata

The model registry now separates four concepts:

```text
model.name        canonical registered variant identity
model.displayName human-facing model name
model.familyName  constitutive family identity
model.order       polynomial order where meaningful
```

For Neo-Hookean and Mooney-Rivlin, `familyName` equals the canonical model name and `order = NaN`.

For Yeoh:

```text
model.name        = yeoh-second-order / yeoh-third-order
model.displayName = Yeoh second order / Yeoh third order
model.familyName  = yeoh
model.order       = 2 / 3
```

Fitting, selection, plotting, reporting, and statistics continue to consume registry metadata rather than duplicate Yeoh-specific logic.

### Fitting and selection integration

Existing fitting and selection implementations required no model-specific production branches. They already consume registry metadata for parameter count, bounds, initial guesses, evaluation, and parsimony.

Validated architecture paths include:

```text
mechanics.models.evaluateModel
mechanics.fitting.fitModel
mechanics.fitting.fitTensileApplicationRangeModel
mechanics.fitting.fitJointModel
mechanics.workflow.selectTensileApplicationRangeModel
mechanics.workflow.selectJointModel
mechanics.workflow.selectStudyConsensusModel
```

### Population and fitting-audit integration

Two previous hard-coded derived-quantity paths were migrated to the registry:

```text
mechanics.statistics.deriveInitialShearModulus
mechanics.workflow.summarizeFittingAudit
```

Both now obtain `mu0` from registered derived-quantity metadata. Yeoh second order therefore participates in population summaries and fitting-audit figures with finite `mu0` values.

Presentation consumers use `displayName`; persisted model identities remain canonical registry names.

### Library defaults

Adding Yeoh second order does not add it to every default candidate set.

The maintained library defaults remain three candidates:

```text
neo-hookean
mooney-rivlin
yeoh-third-order
```

This preserves the previous default scientific policy while making the historical third-order identity explicit.

Changing defaults to include Yeoh second order remains a separate evidence-driven reproducibility decision.

### Real-study drivers

The maintained real drivers explicitly compare all four candidates:

```text
neo-hookean
mooney-rivlin
yeoh-second-order
yeoh-third-order
```

Affected drivers:

```text
studies/tension/run_tensile_experiment.m
studies/compression/run_compression_experiment.m
studies/tension/run_tensile_application_range_characterization.m
studies/joint-characterization/run_joint_material_characterization.m
```

This is an experiment-specific comparison decision and does not alter library defaults.

## Persistence and historical generated results

New MAT/CSV outputs must persist canonical registered identities:

```text
yeoh-second-order
yeoh-third-order
```

Generated results produced before the explicit third-order identity migration may contain:

```text
yeoh
```

for the third-order variant. These files are pre-migration snapshots under ignored `results/` paths and are not a maintained compatibility contract.

When current workflows need those results, regenerate them with current drivers. Do not add `yeoh` back to the registry as an alias and do not add a compatibility wrapper or migration bridge.

Completed-study consumers may continue to use regenerated canonical tensile/compression MAT results without re-importing raw data.

## MATLAB validation status

The final explicit-order migration is locally validated.

The user reported successful execution of the focused migration tests and the complete:

```matlab
run_all_tests()
```

suite after all remaining historical fixtures, including study-consensus-model coverage, were migrated from the removed third-order identifier `yeoh` to `yeoh-third-order`.

Validated coverage includes the constitutive registry/evaluator contract, default candidate sets, fitting, windowed selection, tensile application-range fitting and selection, joint characterization, study consensus, population summaries, fitting audit, plotting, reporting, export, and persistence-oriented fixtures.

The bare identifier `yeoh` is intentionally rejected by the registry and is not preserved by any compatibility path.

MATLAB was run by the user, not by the assistant.

## Real-data evidence before final identity migration

The user regenerated the maintained real study drivers with both Yeoh orders included before the final third-order identifier migration.

Observed evidence included:

- individual tensile and compression specimen selection continued to favor the third-order Yeoh variant;
- tensile application-range characterization continued to select Mooney-Rivlin;
- in joint characterization, second-order Yeoh achieved a joint objective of approximately `0.001247`, while third-order Yeoh retained approximately `0.000936`, so the third-order variant remained clearly preferred for that dataset;
- human-facing outputs correctly distinguished `Yeoh second order` and `Yeoh third order` after the presentation fixes;
- fitting-audit `mu0` for second-order Yeoh became finite after registry-driven derived-quantity migration.

Those scientific results remain relevant because the final identity migration changes the stored third-order name only, not the constitutive equation or objective.

## Remaining gate before merge

Regenerate the four maintained real drivers once under the final explicit-order registry:

```text
1. real tensile study
2. real compression study
3. tensile application-range characterization
4. joint material characterization and robustness audit
```

Review the regenerated MAT/CSV/Markdown/figures against the pre-migration four-candidate results.

Expected invariant:

```text
all scientific metrics and fitted parameters remain unchanged within numerical tolerance
```

Expected intentional identity change:

```text
historical third-order model id: yeoh
final third-order model id:      yeoh-third-order
```

Also confirm that human-facing outputs continue to show `Yeoh second order` and `Yeoh third order`, and that no newly generated MAT/CSV output persists the bare identifier `yeoh` as a model identity.

Do not merge this branch until this final real-data regeneration is reviewed and the user explicitly authorizes the merge.

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
