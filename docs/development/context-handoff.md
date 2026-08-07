# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Future sessions must resolve the live `main` and `origin/main` SHAs with Git. Historical merge SHAs below are milestones, not permanent branch heads.

## Current merged baseline

The most recent completed maintenance phases are:

```text
PR #51  presentation and Markdown serialization contracts
         merge commit c021ea4f3d3d00f1d345e779aa3ca2efef411bf4

PR #52  explicit second- and third-order Yeoh contracts
         merge commit e8982c1fcfc6ca54f4d2ee457ac990bb4afc5b3d

PR #53  completed compression-study comparison reporting
         merge commit 8f70dedad8d1420595f9d1c1a6be9f0992d8dd60
```

There is no active feature branch required to continue the repository. The former comparison branch was:

```text
feature/compression-study-comparison-visuals
```

It may be removed after local `main` is synchronized.

## Current maintained capabilities

### Constitutive models

Registered model identities are:

```text
neo-hookean
mooney-rivlin
yeoh-second-order
yeoh-third-order
```

The Yeoh family uses one evaluator:

```text
mechanics.models.yeoh
```

with explicit variants:

```text
yeoh-second-order -> C10, C20       -> order 2
yeoh-third-order  -> C10, C20, C30  -> order 3
```

Both use:

```text
familyName = yeoh
mu0 = 2 * C10
```

The bare identifier `yeoh` is not a registered model identity and must not be restored as an alias. No wrappers, bridge files, duplicate Yeoh evaluators, or model-specific fitting paths are maintained.

Human-facing names remain registry metadata:

```text
Yeoh second order
Yeoh third order
```

Persisted model identities use the canonical registered names.

### Yeoh default-policy decision remains pending

Library defaults remain:

```text
neo-hookean
mooney-rivlin
yeoh-third-order
```

Maintained real-study drivers explicitly compare:

```text
neo-hookean
mooney-rivlin
yeoh-second-order
yeoh-third-order
```

Whether `yeoh-second-order` should become part of library default candidate sets remains intentionally unresolved. Current real-data evidence supports keeping the conservative defaults: third-order Yeoh is materially better in joint characterization, while tensile application-range characterization selects Mooney-Rivlin.

Revisit this policy only when additional datasets, repeated experiments, or an explicit methodological decision to routinely test nested Yeoh orders justify changing the default model-selection experiment. Do not change the defaults as unrelated maintenance.

## Compression completed-study comparison

The maintained public entrypoint is:

```matlab
mechanics.workflow.compareCompressionStudies
```

The architecture remains:

```text
compareCompressionStudies
    -> compareUniaxialStudies
        -> analyzeGroupComparison
```

A completed-study comparison consumes canonical completed study results. It must not re-import raw workbooks or duplicate extraction, cycle selection, preprocessing, constitutive fitting, or study population analysis.

The maintained Ecoflex driver is:

```text
studies/compression/run_compression_material_comparison.m
```

It currently compares:

```text
Ecoflex 00-20
results/real-compression-study-ecoflex0020/compression_study.mat

Ecoflex 00-50
results/real-compression-study/compression_study.mat
```

and writes generated output under:

```text
results/compression-ecoflex0020-vs-0050/
```

The local Ecoflex 00-20 raw workbook is:

```text
data/raw/Compression_ASTM_D575_ECOFLEX0020_test.xlsx
```

Raw experimental data and generated results remain ignored repository-local artifacts.

### Comparison outputs established by PR #53

The maintained comparison bundle includes:

```text
group_summary.csv
pairwise_curve_comparison.csv
pairwise_metric_comparison.csv
group_model_initial_shear_modulus.csv
group_comparison.png
group_comparison.fig
group_metric_comparison.png
group_metric_comparison.fig
group_tangent_modulus_comparison.png
group_tangent_modulus_comparison.fig
group_comparison.mat
group_comparison_report.md
```

The stress-strain comparison presents:

- the mean curve of each group;
- a pointwise bootstrap confidence band for each group mean;
- a pointwise bootstrap interval for the pairwise difference;
- for compression only, the lower-panel presentation convention `|stress_B| - |stress_A|` while stored stresses retain physical negative signs.

The tangent-modulus comparison presents both population tangent-modulus curves over their common supported strain range and, when available, registry-derived model initial shear references `mu0`. The `mu0` references are horizontal model-derived stiffness references, not tangent-modulus predictions.

The scalar metric figure shows individual specimen values and group means for:

```text
MaximumStrain
MaximumStress
MedianTangentModulus
```

with compact bootstrap interval annotations.

The Markdown report follows the maintained boundary-oriented reporting style used elsewhere. Its `Interpretation boundaries` section is generic and does not encode Ecoflex-specific conclusions or equate bootstrap interval exclusion of zero with a formal hypothesis-test significance result.

## Ecoflex 00-20 versus 00-50 real-data review

The final PR #53 output bundle was regenerated by the user and reviewed before merge.

Observed group means were approximately:

```text
Maximum strain
Ecoflex 00-20: 0.38248
Ecoflex 00-50: 0.37653
A - B:        +0.00594
95% bootstrap interval: [-0.01324, +0.02243]

Maximum stress magnitude
Ecoflex 00-20: 0.09964 MPa
Ecoflex 00-50: 0.21519 MPa

Median tangent modulus
Ecoflex 00-20: 0.19775 MPa
Ecoflex 00-50: 0.47282 MPa

Model-derived initial shear modulus
Ecoflex 00-20: 0.04268 MPa
Ecoflex 00-50: 0.11266 MPa
ratio 00-50 / 00-20: approximately 2.64
```

The reviewed outputs consistently show larger compressive-stress magnitude, tangent modulus, and model-derived initial shear reference for Ecoflex 00-50. The maximum-strain bootstrap interval includes zero, so the maintained report does not claim a clear directional separation for that metric.

These observations are descriptive results of the configured comparison workflow and should not be relabeled as formal hypothesis-test significance without adding an explicit maintained inferential contract.

## MATLAB validation status

The Yeoh-family phase merged through PR #52 is explicitly validated: the user reported successful focused tests and `run_all_tests()` after the final Yeoh identity migration.

For the PR #53 comparison phase:

- the user executed the real Ecoflex comparison repeatedly during development;
- early focused-test failures were reported and corrected;
- the final generated bundle after all presentation/report refinements was supplied and reviewed before merge;
- the conversation does not contain an explicit final statement that the complete MATLAB suite passed after the last refinements.

Therefore do not state that the final PR #53 code has a documented full-suite pass unless the user supplies that result in a later session. The merged implementation and real-data output review are established; the exact final full-suite validation status is not documented here.

MATLAB execution was performed by the user, not by the assistant.

## Previous real-data Yeoh validation

The final four-candidate joint characterization produced approximately:

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

Tensile application-range characterization retained Mooney-Rivlin with approximately:

```text
C10 = 0.023122 MPa
C01 = 0.005407 MPa
mu0 = 0.057058 MPa
```

Range-sensitivity scenarios at `0.30`, `0.40`, and `0.50 mm/mm` all retained Mooney-Rivlin.

## Presentation and persistence contracts

Stored physical values are not rescaled or sign-flipped in persisted results solely for presentation.

Maintained unit responsibilities are:

```text
mechanics.plotting.resolveStudyUnits
mechanics.plotting.mechanicalDisplayUnit
mechanics.plotting.mechanicalAxisLabel
mechanics.plotting.formatUnitLabel
```

Human-facing conventions include:

```text
dimensionless deformation -> mm/mm
stress and stress-like quantities -> stored stress unit
normalized quantities -> [-]
```

`mechanics.io.writeMarkdownTable` remains the shared scalar Markdown serializer for the established equivalent table contract. Report writers with materially different serialization behavior remain separate.

Generated pre-migration results that contain the historical third-order model identifier `yeoh` are not a maintained compatibility contract. Regenerate them with current drivers rather than adding an alias or migration bridge.

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
- Maintained root MATLAB entrypoints are only `startup.m` and `run_all_tests.m`.
- Extract shared code only when at least two maintained callers use the same physical and data contract.
- Do not create wrappers, aliases, bridge files, or one-caller helpers for superficial symmetry.
- Do not reorganize packages merely for visual balance.
- Preserve public APIs unless a demonstrated ambiguity or ownership defect justifies migration.
- Use the model registry rather than scattering model-name conditionals when contracts are identical.
- Keep model evaluation in `mechanics.models`, optimization in `mechanics.fitting`, population inference in `mechanics.statistics`, deterministic calculations in `mechanics.analysis`, presentation in `mechanics.plotting`, serialization in `mechanics.io`, and orchestration in `mechanics.workflow`.
- Keep tensile, compression, joint-characterization, tensile application-range, and completed-study comparison workflows distinct.
- Completed-study add-ons and comparisons consume canonical completed study results; they do not re-import raw data.
- Preserve stored physical values and signs. Presentation conventions must not silently alter numerical state.
- Generated data and outputs remain under ignored `results/` paths.
- Do not merge a pull request unless explicitly requested.

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
6. inspect maintained callers and tests before proposing moves or shared helpers;
7. define the smallest coherent phase and its validation gate before implementation.
