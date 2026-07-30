# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Validated merged baseline

The current merged baseline is PR #42:

```text
8a056db15b7060a4807bccea769710ff8c1e026b
```

It includes the maintained tension and compression workflows, individual model selection, consensus-model population analysis, reporting and comparison utilities, and C1-C5 joint material characterization with robustness auditing.

## Active branch and scope

```text
fix/joint-sign-tolerance
```

This branch addresses one real-data incompatibility discovered during the first maintained joint tension-compression run: isolated tensile stress observations slightly below zero were rejected as sign violations even though their magnitude was negligible relative to specimen response.

The branch is limited to:

- configurable scale-aware sign-validation tolerances;
- preservation of all stored observations without clipping or zeroing;
- tests for accepted near-zero noise and rejected material sign violations;
- documentation of the first real joint characterization and robustness results.

Focused tests and the complete `run_all_tests()` suite passed.

## A and B responsibilities

### A. Individual-study workflows — implemented

Tension and compression preserve processed curves, mechanical metrics, individual fits and selections, population summaries, CSV, MAT, figures, and reports.

### B. Individual selection and consensus population — implemented

Individual model selection remains specimen-specific. The optional consensus workflow chooses a majority model within one study mode and refits retained specimens with that model. It is not joint tension-compression characterization.

## C. Joint material characterization — implemented and run on real data

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

### Sign-tolerance evidence

The tensile studies contained isolated negative stress observations near the zero reference:

```text
minimum values: approximately -4.3e-5 to -2.0e-4 MPa
maximum specimen stresses: approximately 1.49 to 1.73 MPa
negative points: 0 to 4 per specimen
```

These excursions are at most approximately `0.011 %` of specimen maximum stress and are interpreted as acquisition or zero-reference noise, not physical compression.

Configuration:

```matlab
config.signTolerance.deformationRelative = 1e-8;
config.signTolerance.stressRelative = 1e-3;
config.signTolerance.absolute = 100 * eps;
```

The tolerances validate sign conventions only. Stored deformation and stress vectors remain unchanged and are passed directly to fitting. Larger sign reversals remain errors.

### Real selected model

The first real joint run used four tensile and four compression specimens and 22,006 total observations.

Selected model:

```text
yeoh
```

Selected parameters:

```text
C10 = 0.0524808 MPa
C20 = 1.98662e-4 MPa
C30 = 4.04826e-6 MPa
```

Joint objective:

```text
0.00093633
```

Neo-Hookean and Mooney-Rivlin each had objectives of approximately `0.016832`, so Yeoh was clearly preferred rather than selected through a marginal practical-equivalence decision.

Mean normalized RMSE:

```text
tension:     approximately 3.94 %
compression: approximately 1.66 %
```

### Real robustness audit

The maintained driver stores the optional audit result as:

```matlab
robustnessAudit
```

Yeoh remained selected for every default one-factor-at-a-time scenario.

```text
baseline                     parameter change 0
asymmetric mode weights      maximum parameter change 2.2449 %
50 % sampling density        parameter change 0.0113 %
75 % deformation range       parameter change 1.1781 %
one specimen per mode        parameter change 0.8677 %
```

Model identity was stable in all scenarios. The largest parameter change occurred under heavier tensile weighting and remained below 2.3 %. Halving observation density produced negligible change, supporting the hierarchical objective rather than pooled point-count weighting.

The present evidence supports the equal-specimen, equal-mode, response-range-normalized contract for this dataset. It does not justify adding alternative weighting or normalization methods automatically.

## Maintained result bundle

```text
joint_material_characterization.mat
candidate_model_summary.csv
selected_joint_parameters.csv
mode_fit_summary.csv
specimen_fit_summary.csv
joint_material_characterization.md
joint_fit_tension.png
joint_fit_tension.fig
joint_fit_compression.png
joint_fit_compression.fig
```

The robustness audit is currently retained in the MATLAB workspace and printed by the driver; it is not included in the base exported bundle.

## Current status

Completed:

- C1-C5 implementation;
- synthetic validation;
- first real tension-compression characterization;
- real robustness interpretation;
- sign-tolerance correction and tests.

Pending:

- merge of the active sign-tolerance pull request;
- separately scoped decision on whether robustness results should be exported persistently;
- real validation of the two-study tensile comparison export;
- any future model or experimental-mode extension supported by actual need.

Do not start another implementation phase automatically. Select the next objective from real evidence and keep it limited.

## Deferred decisions

- single-mode consensus majority policy;
- Yeoh-2 as a separate registered model;
- Ogden or other additional models;
- modes beyond tension and compression;
- alternative joint normalization or weighting strategies;
- cross-validation or fitting-window sensitivity;
- persistent robustness-audit export.

Do not implement these without an approved limited phase and supporting evidence.

## Validation protocol

For each future phase:

1. run focused behavioral tests using existing file names;
2. run `run_all_tests()`;
3. inspect generated artifacts when outputs exist;
4. use synthetic recovery before interpreting real fits;
5. record real-data evidence and unavailable validation explicitly.

## Repository verification

```bash
git fetch origin --prune
git switch main
git pull --ff-only origin main
git status -sb
git rev-parse HEAD
git rev-parse origin/main
```

Do not continue work on a branch after its PR has been merged.

## Maintenance rules

- Share code only for genuinely shared physical and data contracts.
- Keep reusable implementation under `src/+mechanics` and real drivers under `studies`.
- Do not preserve obsolete APIs through wrappers or aliases.
- Do not add bridge files for superficial symmetry.
- Use the model registry instead of model-name conditionals where contracts match.
- Maintain relevant, nonredundant outputs.
- Do not merge a pull request unless explicitly requested.
