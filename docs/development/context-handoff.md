# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Validated merged baseline

The current merged baseline is PR #38:

```text
ec8b24c37eca64120dc078b24863af0b6ef0bc1a
```

It includes the maintained tension and compression workflows, individual model selection, consensus-model population analysis, study reporting, tensile-study comparison export, and C1 joint-characterization input normalization.

## Active branch and scope

```text
feature/joint-fixed-model-fitting
```

This branch implements C2 only: fitting one registered constitutive model across normalized independent tension and compression specimens using one shared parameter vector and a hierarchical specimen-mode objective.

Focused C2 tests passed and the complete `run_all_tests()` suite passed.

An attempted focused run referenced `tests/test_model_fitting.m`, which does not exist. MATLAB therefore failed while constructing that test suite. This was a command-path error, not a failing repository test or implementation failure.

## A and B responsibilities

### A. Individual-study workflows — implemented

Tension and compression preserve processed curves, mechanical metrics, individual fits and selections, population summaries, CSV, MAT, figures, and reports.

### B. Individual selection and consensus population — implemented

Individual model selection remains specimen-specific. The optional consensus workflow chooses a majority model within a study mode and refits retained specimens with that model. It is not joint tension-compression characterization.

## C. Joint material characterization

C estimates one constitutive parameter set from independent experimental modes. Initial real modes are uniaxial tension and uniaxial compression. Specimens are unpaired.

Canonical documentation:

```text
docs/workflows/joint-material-characterization.md
```

Planned final workflow:

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

Planned maintained driver:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

## C1 — completed

Implemented:

```matlab
config = mechanics.config.jointMaterialCharacterizationConfig();
mode = mechanics.workflow.jointCharacterizationModeRegistry(modeName);
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
```

C1 consumes completed studies, preserves physical signs and sampling grids, accepts unequal specimen counts, namespaces duplicate identifiers, maps measures to model contexts, validates units and weights, and creates no synthetic pairing.

## C2 — implemented on the active branch

Entry point:

```matlab
fit = mechanics.fitting.fitJointModel( ...
    normalized, modelName, config);
```

C2:

- fits one registered model using one common parameter vector;
- reuses the model registry, evaluation, bound transformation, multistart generation, and `fminsearch` configuration;
- computes a response-range-normalized loss per specimen;
- averages specimen losses within each mode;
- combines mode losses using positive normalized weights resolved by mode name;
- preserves physical residuals, predictions, RMSE, normalized RMSE, and maximum absolute error;
- retains multistart results and convergence metadata.

The default gives equal influence to specimens within each mode and equal total influence to tension and compression. Point count and specimen count do not automatically determine material influence.

Synthetic tests verified Neo-Hookean parameter recovery, unequal specimen counts, different sampling densities, reordered mode inputs, configured mode weights, predictions, residuals, and configuration errors.

C2 does not perform multi-model comparison or selection.

## C3 — next objective

C3 must remain limited to multi-model fitting and joint selection.

Required behavior:

- fit every model in `config.candidateModelNames` through `fitJointModel`;
- retain all candidate fits and diagnostics;
- define candidate eligibility explicitly;
- rank eligible candidates using practical fit equivalence, parsimony, an appropriate information criterion where valid, and deterministic configured ordering;
- select one joint model without changing A or B selections;
- test failed candidates, deterministic ties, parsimony, and recovery when the generating model is present.

C3 must not add the driver, report bundle, new constitutive models, or unsupported experimental modes.

## Later phases

### C4 — maintained driver and outputs

Add:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

Load completed tension and compression MAT studies without reprocessing raw data and export the joint MAT, candidate summary, selected parameters, mode/specimen summaries, Markdown report, and mode-specific PNG/FIG files.

### C5 — robustness and extensibility

Audit mode weights, normalization, sampling density, and deformation range. Add alternatives only when supported by evidence. Do not implement modes without real data and physical contracts.

## Deferred decisions

- single-mode consensus majority policy;
- Yeoh-2 as a separate registered model;
- Ogden or other additional models;
- real validation of two-study tensile comparison export;
- modes beyond tension and compression.

Do not combine these with C3.

## Validation protocol

For each phase:

1. run focused behavioral tests using existing file names;
2. run `run_all_tests()`;
3. inspect generated artifacts when outputs exist;
4. use synthetic recovery before interpreting real fits;
5. record unavailable real-data validation explicitly.

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
