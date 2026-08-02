# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested. The documentation updates that prepared this handoff were explicitly authorized as direct `main` changes.

## Validated merged implementation baseline

The latest merged implementation baseline is PR #43:

```text
e767e379ac91ca5a6820139d6b8aefff9c0ccb84
```

It includes maintained tension and compression workflows, specimen-specific model selection, consensus-model population analysis, reporting and comparison utilities, C1-C5 joint material characterization, robustness auditing, and scale-aware joint sign validation.

Direct documentation commits after this baseline define the next approved planning target. They do not implement that target.

## Validated but unmerged plotting branch

```text
fix/fitting-plot-clarity
```

This branch contains accepted joint-characterization plotting improvements:

- measured specimens as thin continuous curves;
- one population median over the common observed domain;
- one black dashed selected joint fit;
- dynamic model parameters;
- registry-derived reference quantities;
- TeX rendering of `mu` and `mu0` as `\mu` and `\mu_0`;
- behavioral plotting tests.

The user reported that focused and complete tests passed and that the real tension and compression figures look correct.

The branch was not merged in the previous session. Do not assume its code is on `main`. Before starting implementation of the next phase, inspect the branch and repository status. Do not merge it without explicit user instruction, and do not continue unrelated implementation on it.

## Implemented responsibilities

### A. Individual-study workflows

Tension and compression preserve processed curves, mechanical metrics, individual fits and selections, population summaries, CSV, MAT, figures, and reports.

### B. Individual selection and consensus population

Individual model selection remains specimen-specific. The optional consensus workflow chooses a majority model within one study mode and refits retained specimens with that model. It is not joint tension-compression characterization.

### C. Joint material characterization

Canonical documentation:

```text
docs/workflows/joint-material-characterization.md
```

Public workflow:

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

Maintained driver:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

Real input files:

```text
results/real-tensile-study/tensile_study.mat
results/real-compression-study/compression_study.mat
```

Both files contain one completed study variable named `study`.

The first real joint run used four tensile and four compression specimens and 22,006 observations. Yeoh was selected with:

```text
C10 = 0.0524808 MPa
C20 = 1.98662e-4 MPa
C30 = 4.04826e-6 MPa
objective = 0.00093633
```

Mean normalized RMSE was approximately `3.94 %` for tension and `1.66 %` for compression. Yeoh remained selected throughout the default one-factor robustness audit, with a maximum parameter change below `2.3 %`.

## Next approved planning target: D

### D. Tensile application-range characterization

Canonical design:

```text
docs/workflows/tensile-application-range-characterization.md
```

Status:

```text
approved for future implementation; no implementation exists yet
```

Purpose:

> Estimate one shared hyperelastic parameter set from a completed tensile study inside a configured loading interval, with parsimonious model selection, registry-derived reference properties, fit-range sensitivity, and optional compression validation without refitting.

This is a maintained add-on to the tensile study, not a replacement for it and not a peer with the same scope as joint material characterization.

Architecture:

```text
runTensileStudy
    -> completed tensile study
    -> runTensileApplicationRangeCharacterization
```

Preferred planned entrypoint:

```matlab
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);
```

Preferred planned configuration:

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.fitRange.deformationMeasure = "engineering-strain";
config.fitRange.minimum = 0;
config.fitRange.maximum = 0.30;
config.candidateModelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
```

Names may be refined during D1 only if existing repository conventions support a simpler contract.

### Required architectural principles for D

- Consume a completed tensile study; never re-import raw workbooks.
- Reuse all existing tensile preparation and constitutive infrastructure whose physical and data contracts are identical.
- Reuse solver, multistart, bounds, model registry, diagnostics, practical-equivalence ranking, plotting, export, and reporting where contracts match.
- Preserve equal influence per specimen; do not use pooled pointwise SSE that rewards denser sampling.
- Fit one shared parameter vector per candidate model across retained tensile specimens.
- Preserve the full source curves and record the exact fitted interval and included/excluded observations.
- Select parsimoniously when limited-range data do not distinguish models materially.
- Derive reference quantities such as `mu0` through the model registry, not workflow or plotting conditionals.
- Treat estimates from different calibration contracts as protocol-dependent estimates of one reference property, not separate intrinsic tensile and compression moduli.
- Audit sensitivity only to the application-range boundary unless real evidence supports more.
- Allow compression only as optional prediction validation with fixed tensile-calibrated parameters and no refitting.
- Extract a shared lower-level helper only when at least two maintained callers use the same contract.
- Do not create wrappers, aliases, compatibility shims, bridge files, or one-caller helpers for superficial symmetry.

### Explicit exclusions for D

Do not implement:

- OCE or OCT concepts;
- Lamb waves or any wave propagation;
- acoustoelasticity or small-on-large theory;
- incremental elasticity tensors or directional moduli;
- dispersion inversion;
- viscoelasticity;
- a separate fit at each deformation state;
- new constitutive models without evidence;
- duplicated tension or joint workflows.

These topics are outside the maintained repository scope for this phase.

### Proposed D phases

#### D1 — Reuse audit and contracts

- inspect completed tensile-study structures and existing fitting, ranking, registry, plotting, and export functions;
- identify direct reuse and any genuinely shared lower-level contract;
- finalize config, input validation, result structure, error identifiers, and tests;
- do not implement fitting until the reuse decision is explicit.

#### D2 — Range-limited shared fitting

- extract retained processed tensile loading curves;
- restrict observations to the configured interval without modifying data;
- fit one shared parameter vector per candidate model;
- preserve equal-specimen influence;
- validate with synthetic recovery and sampling-density tests.

#### D3 — Selection and reference properties

- reuse or generalize practical-equivalence and parsimonious selection only where contracts match;
- expose registry-derived reference properties;
- verify model-agnostic behavior for Neo-Hookean, Mooney-Rivlin, and Yeoh.

#### D4 — Range sensitivity and optional validation

- implement one-factor sensitivity to the maximum fitted deformation;
- optionally predict compression without refitting;
- compare calibration-contract estimates without redefining multiple intrinsic `mu0` values.

#### D5 — Driver, export, documentation, and real validation

- add the maintained tension add-on driver;
- export a limited nonredundant result bundle;
- run focused tests and `run_all_tests()`;
- execute the real tensile application-range analysis;
- inspect figures and tables;
- record supported and inconclusive findings.

Do not begin D2 automatically after D1. Review each phase before continuing.

## Proposed maintained driver and local inputs

Driver:

```text
studies/tension/run_tensile_application_range_characterization.m
```

Primary local input:

```text
results/real-tensile-study/tensile_study.mat
```

Optional validation input:

```text
results/real-compression-study/compression_study.mat
```

Local data and generated outputs remain ignored and must not be committed.

## Existing deferred decisions

- persistent robustness-audit export;
- real validation of two-study tensile comparison export;
- single-mode consensus majority policy;
- Yeoh-2 as a separate registered model;
- Ogden or other additional models;
- modes beyond tension and compression;
- alternative joint normalization or weighting strategies.

Do not implement these inside D unless direct evidence and explicit approval change the phase scope.

## Validation protocol

For each future phase:

1. run focused behavioral tests using existing file names where possible;
2. run `run_all_tests()`;
3. inspect generated artifacts when outputs exist;
4. use synthetic recovery before interpreting real fits;
5. record real-data evidence and unavailable validation explicitly;
6. do not claim MATLAB tests passed until the user reports the result;
7. do not merge a pull request unless explicitly requested.

## Repository verification

At the start of the next session:

```bash
git fetch origin --prune
git switch main
git pull --ff-only origin main
git status -sb
git rev-parse HEAD
git rev-parse origin/main
```

Then inspect the unmerged plotting branch:

```bash
git log --oneline --decorate main..origin/fix/fitting-plot-clarity
git diff --stat main...origin/fix/fitting-plot-clarity
```

Do not continue work on a branch after its PR has been merged. Create a new branch for D1 only after the baseline and plotting-branch status are resolved.

## Maintenance rules

- Favor simplicity, structure, order, and explicit contracts.
- Share code only for genuinely shared physical and data contracts.
- Keep reusable implementation under `src/+mechanics` and real drivers under `studies`.
- Do not preserve obsolete APIs through wrappers or aliases.
- Do not add bridge files for superficial symmetry.
- Use the model registry instead of model-name conditionals where contracts match.
- Maintain relevant, nonredundant outputs.
- Keep tension and compression independently useful.
- Keep individual model selection specimen-specific.
- Keep joint tension-compression characterization separate from the tensile application-range add-on.
- Do not merge a pull request unless explicitly requested.
