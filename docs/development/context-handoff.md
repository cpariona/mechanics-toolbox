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

The current `main` baseline after the PR #53 documentation closeout is:

```text
cd039dcc797271e675147630e535f72304e0b30b
```

Always verify the live remote branch before continuing.

## Active development state

Active branch:

```text
feature/unify-study-consensus-population
```

**Continue all work for this phase on this existing branch. Do not switch back to `main` and do not create another feature branch.** The generic session-bootstrap instruction to create a dedicated branch is already satisfied by this branch.

This phase removes a redundancy in the standard tensile and compression study drivers without removing the advanced common-model refit API.

The standard study population now owns a descriptive summary of the individual constitutive model selections under:

```text
study.population.modelSelection
```

It records individual selections, candidate selection counts/fractions, a unique selection-frequency consensus when one exists, and unanimity. This standard consensus is descriptive only and performs no second fit.

The normal tensile and compression drivers no longer generate a separate `consensus-model-population` folder merely to repeat the same parameter population when all retained specimens selected the same model. `fitConsensusModelAcrossSpecimens`, `summarizeSelectedParameters`, and `exportSelectedParameterPopulation` remain available for explicit advanced workflows that truly require every specimen to be refit with one common model.

The standard selected-model parameter population remains the canonical source of per-specimen fitted parameters. It now also retains registry-derived initial shear modulus values so standard reports can visualize parameter and `mu0` variation across specimens without invoking a consensus refit.

Standard report presentation in this active branch includes:

```text
selected_model_parameters.png/.fig
initial_shear_modulus.png/.fig
```

for both tensile and compression population reports when selected-model parameter data are available.

The individual tangent-modulus figures mark the configured summary interval. The maintained compression multi-specimen figure no longer overlays horizontal per-specimen summary lines; the derivative curves remain the primary visual content. Population tangent-modulus figures keep individual curves visible, restrict legends to graphical/statistical elements, mark the summary interval, and annotate the canonical population scalar inside the axes.

The tensile `zero_reference_diagnostics` figure is now a local diagnostic centered on the selected zero-reference sample. The default half-window is 30 acquisition points on either side and is configurable through `tensileStudyReportConfig.zeroReferenceDiagnosticHalfWindowPoints`.

The presentation-consistency implementation is now complete in code:

- maintained study figures use concise scientific titles rather than material,
  workbook, experiment, or filename metadata;
- specialized scientific titles in model selection, joint characterization,
  validation, sensitivity, reliability, and completed-study comparison remain;
- the initial-shear figure follows the population `centralStatistic`, showing
  mean with descriptive SD when available or median without a misleading
  `median ± SD`; its value remains registry-derived;
- the tangent-modulus population stores the specimen `MedianTangentModulus`
  values, the configured population central statistic and scalar, and summary
  interval metadata used by MAT, CSV, Markdown, and figure output;
- compression analysis supports `explicit` and `proportional`
  `summaryStrainRangeMode` values. The real compression driver now explicitly
  uses the signed interval `[-0.10, -0.01]`, corresponding to compression-strain
  magnitudes from `0.01` to `0.10`;
- stored compression values retain negative physical signs, while report figures
  continue to use the maintained positive-magnitude display convention.

The current real compression driver therefore reports `MedianTangentModulus` for
a fixed physical window rather than for the complete retained strain span. This
is an intentional analysis-setting change from the earlier proportional `[0, 1]`
configuration. Results regenerated before and after this final window change
must not be described as numerically equivalent without comparison.

The report writers remain serializers of stored results. They do not run fitting,
bootstrap, model selection, or tangent-modulus analysis.

### Validation gate for the active branch

Do not merge this branch until all of the following are satisfied:

1. focused MATLAB tests covering the modified existing contracts pass;
2. `run_all_tests()` passes on the user's local MATLAB installation;
3. the real tensile and compression study drivers regenerate successfully;
4. the user visually reviews the relevant PNG outputs and Markdown reports;
5. the branch diff is audited for unnecessary files, helpers, duplicated contracts, and stale documentation;
6. canonical documentation reflects the final implementation rather than intermediate plans.

MATLAB R2024b was available for the main implementation. The focused and complete
suite results recorded below were executed before the final compression-only
presentation/window adjustment. The latest removal of compression per-specimen
summary lines and the change to the explicit `[-0.10, -0.01]` summary interval
still require a final user-side compression regeneration and focused validation.

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

For the active `feature/unify-study-consensus-population` phase, MATLAB R2024b
validation completed on 2026-08-11 before the final compression-only adjustment:

- the focused plotting, population, reporting, and model-selection set passed
  `41/41` before final layout refinement;
- `run_all_tests()` passed `293/293`, with zero failures and zero incomplete
  tests;
- both maintained real drivers completed and regenerated their standard bundles;
- the final layout-only refinement passed the affected tensile reporting tests
  `7/7` after the complete suite;
- key regenerated tangent-modulus and initial-shear figures were inspected for
  clipping, annotation placement, units, titles, and legend semantics.

Under the preceding configuration, the regenerated tensile population scalar was
approximately `0.089545 MPa` and the regenerated compression scalar was
approximately `0.47113 MPa`; the compression mean was approximately `0.47282 MPa`.
Those compression values correspond to the prior proportional `[0, 1]` summary
window and must not be treated as the expected result of the new explicit
`[-0.10, -0.01]` configuration.

The user subsequently confirmed the regenerated outputs were functioning and
requested the final compression-only adjustments now present in the branch:
removal of horizontal per-specimen summary lines from `tangent_modulus` and the
explicit `0.01` to `0.10` compression-strain-magnitude summary window. These
latest changes require one final compression regeneration before merge or PR.

No merge or PR has been performed.

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

For a **new unrelated phase**, the generic bootstrap is:

1. read this file completely;
2. read `docs/development/repository-structure.md`;
3. read the relevant workflow and testing documents;
4. verify Git state;
5. create a dedicated branch unless the user explicitly requests direct work on `main`.

For the **currently active phase**, do not apply step 5 again. Continue on:

```text
feature/unify-study-consensus-population
```

Before editing the active phase, verify:

```bash
git fetch origin --prune
git switch feature/unify-study-consensus-population
git pull --ff-only origin feature/unify-study-consensus-population
git status -sb
git diff --check origin/main...HEAD
```

Then inspect maintained callers and tests before extracting, moving, deleting, or generalizing functions. Define the smallest coherent implementation steps and preserve the validation gate above.
