# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

## Current merged baseline

The explicit second- and third-order Yeoh model contracts were merged through PR #52.

PR #52 merge commit:

```text
e8982c1fcfc6ca54f4d2ee457ac990bb4afc5b3d
```

The earlier presentation-contract and Markdown-serialization maintenance phase was merged through PR #51 with merge commit:

```text
c021ea4f3d3d00f1d345e779aa3ca2efef411bf4
```

Future sessions must resolve the live `main` and `origin/main` SHAs with Git rather than treating either historical merge commit above as the permanent branch head.

## Active development state

There is no active Yeoh feature branch required for continued work. The Yeoh-family implementation, regression validation, real-driver regeneration, and documentation are complete and merged on `main`.

The former feature branch was:

```text
feature/yeoh-second-order
```

It may be deleted locally and remotely after the user's working copy is synchronized with `main`.

The current experiment-specific follow-up is compression material comparison between Ecoflex 00-20 and Ecoflex 00-50 using completed ASTM D575 study results. The maintained comparison workflow already exists; a real-study driver has been added under:

```text
studies/compression/run_compression_material_comparison.m
```

It consumes completed study bundles and does not re-import raw workbooks.

## Yeoh family contract

### Registered naming

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

`mechanics.models.yeoh` is the single evaluator for the Yeoh family. It accepts exactly two or three parameters:

```text
[C10, C20]       -> second-order Yeoh
[C10, C20, C30]  -> third-order Yeoh
```

The third-order constitutive expression is numerically unchanged from the implementation that preceded PR #52.

### Registry metadata

The model registry separates four concepts:

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

Fitting, selection, plotting, reporting, and statistics consume registry metadata rather than duplicate Yeoh-specific logic.

### Fitting and selection integration

Existing fitting and selection implementations required no model-specific production branches. They consume registry metadata for parameter count, bounds, initial guesses, evaluation, and parsimony.

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

Both obtain `mu0` from registered derived-quantity metadata. Yeoh second order therefore participates in population summaries and fitting-audit figures with finite `mu0` values.

Presentation consumers use `displayName`; persisted model identities remain canonical registry names.

### Library defaults

The maintained library defaults remain three candidates:

```text
neo-hookean
mooney-rivlin
yeoh-third-order
```

`yeoh-second-order` is registered and available but is not included automatically in the library default candidate sets.

The maintained real-study drivers explicitly compare all four candidates:

```text
neo-hookean
mooney-rivlin
yeoh-second-order
yeoh-third-order
```

This preserves the previous default scientific policy while allowing explicit evidence-driven comparison of both Yeoh orders in maintained experiments.

### Pending default-policy decision

Whether `yeoh-second-order` should become part of the library default candidate sets remains intentionally unresolved.

Current real-data evidence supports keeping the conservative defaults for now: third-order Yeoh remains materially better than second-order Yeoh in the joint characterization, while tensile application-range characterization selects Mooney-Rivlin. This is not a permanent rejection of second-order Yeoh as a default candidate.

Revisit this policy when additional datasets, repeated experiments, or a clearly stated methodological preference for routinely testing nested Yeoh orders provide enough evidence to justify changing the default model-selection experiment.

Do not silently change the default candidate sets as part of unrelated maintenance.

## Compression completed-study comparison

The maintained public entrypoint is:

```matlab
mechanics.workflow.compareCompressionStudies
```

It delegates to the shared uniaxial completed-study comparison contract, validates compatible mechanics measures and units, reconstructs one population per study, compares pairwise population stress-strain curves over their common strain domain, compares scalar study metrics, and can export the group-comparison bundle.

The maintained real driver for Ecoflex comparison is:

```text
studies/compression/run_compression_material_comparison.m
```

It expects completed studies at:

```text
results/real-compression-study-ecoflex0020/compression_study.mat
results/real-compression-study/compression_study.mat
```

corresponding to Ecoflex 00-20 and Ecoflex 00-50, respectively.

The comparison output is written under:

```text
results/compression-ecoflex0020-vs-0050/
```

The Ecoflex 00-20 raw workbook is local experimental data:

```text
data/raw/Compression_ASTM_D575_ECOFLEX0020_test.xlsx
```

It must first be processed with the maintained compression-study workflow and exported to the dedicated Ecoflex 00-20 result folder above. Do not overwrite the existing Ecoflex 00-50 `results/real-compression-study` bundle.

The comparison driver itself must continue to consume completed study MAT files rather than duplicate ASTM D575 extraction, cycle selection, preprocessing, constitutive fitting, or population analysis.

## Persistence and historical generated results

New MAT/CSV outputs persist canonical registered identities:

```text
yeoh-second-order
yeoh-third-order
```

Generated results produced before the explicit third-order identity migration may contain the historical third-order identifier `yeoh`. Those files are pre-migration snapshots under ignored `results/` paths and are not a maintained compatibility contract.

When current workflows need those results, regenerate them with current drivers. Do not add `yeoh` back to the registry as an alias and do not add a compatibility wrapper or migration bridge.

## MATLAB validation status

The merged Yeoh-family implementation is locally validated.

The user reported successful execution of the focused migration tests and the complete:

```matlab
run_all_tests()
```

suite after all remaining historical fixtures, including study-consensus-model coverage, were migrated from the removed third-order identifier `yeoh` to `yeoh-third-order`.

Validated coverage includes the constitutive registry/evaluator contract, default candidate sets, fitting, windowed selection, tensile application-range fitting and selection, joint characterization, study consensus, population summaries, fitting audit, plotting, reporting, export, and persistence-oriented fixtures.

The bare identifier `yeoh` is intentionally rejected by the registry and is not preserved by any compatibility path.

MATLAB was run by the user, not by the assistant.

The new Ecoflex compression material-comparison driver has not yet been locally executed by the user. Its library workflow is pre-existing maintained functionality; real-data validation should occur after the Ecoflex 00-20 completed study has been generated.

## Final real-data validation

After the final identity migration, the user regenerated all maintained real drivers and supplied the complete generated bundle for review.

The inspected CSV and Markdown outputs persist canonical registered identities `yeoh-second-order` and `yeoh-third-order`; human-facing output uses `Yeoh second order` and `Yeoh third order`.

Individual tensile and compression model selection selected `yeoh-third-order` for every retained specimen, and both consensus-model population exports selected `yeoh-third-order` with selection fraction `1.0`.

The final joint characterization produced approximately:

```text
Neo-Hookean objective       ~= 0.016832
Mooney-Rivlin objective     ~= 0.016832
Yeoh second order objective ~= 0.00124659
Yeoh third order objective  ~= 0.000936332
```

Third-order Yeoh remained selected with approximately:

```text
C10 = 0.052481 MPa
C20 = 1.99e-4 MPa
C30 = 4e-6 MPa
```

Mean normalized RMSE remained approximately `3.94 %` in tension and `1.66 %` in compression.

The final tensile application-range characterization retained Mooney-Rivlin as the selected model. Approximate selected properties were:

```text
C10 = 0.023122 MPa
C01 = 0.005407 MPa
mu0 = 0.057058 MPa
```

Range-sensitivity scenarios at `0.30`, `0.40`, and `0.50 mm/mm` all retained Mooney-Rivlin.

These results matched the inspected pre-rename four-candidate results to the reported precision. The explicit-order migration therefore changed model identity and presentation contracts without changing the scientific conclusions or constitutive fits.

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
- `completed-study comparison` compares canonical completed studies without re-importing raw data;
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
- Preserve public APIs unless a demonstrated ambiguity or ownership defect justifies migration.
- Use the model registry rather than scattering model-name conditionals when the contracts are identical.
- Keep model evaluation in `mechanics.models`, optimization in `mechanics.fitting`, population inference in `mechanics.statistics`, deterministic mechanical calculations in `mechanics.analysis`, and orchestration in `mechanics.workflow`.
- Keep individual tensile, compression, joint-characterization, tensile application-range, and completed-study comparison workflows distinct.
- Preserve completed-study add-ons and comparisons as consumers of canonical completed study results; do not re-import or reprocess raw data.
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
