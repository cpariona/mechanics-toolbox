# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Validated merged baseline

The current merged baseline is PR #39:

```text
582f2f75b656da0dcc2dd85751e970a4c8eb1caf
```

It includes the maintained tension and compression workflows, individual model selection, consensus-model population analysis, study reporting, tensile-study comparison export, C1 joint input normalization, and C2 fixed-model joint fitting.

## Active branch and scope

```text
feature/joint-model-selection
```

This branch implements C3 only: fitting all configured registered models through the C2 objective, retaining every candidate, and selecting one joint constitutive model using explicit eligibility, practical equivalence, parsimony, exact objective, and deterministic configured ordering.

Focused C3 tests and the complete `run_all_tests()` suite passed.

## A and B responsibilities

### A. Individual-study workflows — implemented

Tension and compression preserve processed curves, mechanical metrics, individual fits and selections, population summaries, CSV, MAT, figures, and reports.

### B. Individual selection and consensus population — implemented

Individual model selection remains specimen-specific. The optional consensus workflow chooses a majority model within one study mode and refits retained specimens with that model. It is not joint tension-compression characterization.

## C. Joint material characterization

C estimates one constitutive parameter set from independent experimental modes. Initial real modes are uniaxial tension and uniaxial compression. Specimens are independent and unpaired.

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

## C2 — completed

Implemented:

```matlab
fit = mechanics.fitting.fitJointModel( ...
    normalized, modelName, config);
```

C2 fits one registered model using one common parameter vector. It computes a response-range-normalized loss per specimen, averages specimen losses within each mode, and combines mode losses using explicit positive weights resolved by mode name.

C2 retains predictions, physical residuals, physical and normalized RMSE, maximum absolute error, mode and specimen summaries, convergence metadata, and multistart results.

## C3 — implemented on the active branch

Implemented:

```matlab
result = mechanics.workflow.selectJointModel(normalized, config);
```

C3:

- fits every unique model in `config.candidateModelNames` through `fitJointModel`;
- retains completed and failed candidates;
- records error identifiers and messages without interrupting remaining fits;
- defines eligibility from completed finite fits and optional convergence requirements;
- defines practical equivalence from `config.selection.practicalObjectiveTolerance`;
- selects the lowest-parameter equivalent model;
- breaks remaining ties by exact joint objective and `config.selection.tieBreakOrder`;
- retains pooled physical SSE, AIC, and BIC as diagnostics rather than replacing the hierarchical objective;
- preserves the complete selected C2 fit as `result.selectedFit`.

The result contains:

```text
result.modeNames
result.candidates
result.candidateSummary
result.selectedModelName
result.selectedFit
result.selection
result.config
result.createdAt
```

Synthetic tests verified Neo-Hookean parsimony, nonlinear Yeoh recovery, failed-candidate retention, deterministic ordering, configuration validation, and finite AIC/BIC diagnostics.

C3 does not add the public orchestration workflow, driver, reports, figures, exports, new constitutive models, or unsupported modes.

## C4 — next objective

C4 must remain limited to public orchestration, the maintained driver, and the nonredundant result bundle.

Required behavior:

- add `mechanics.workflow.runJointMaterialCharacterization`;
- call the C1 normalizer and C3 selector rather than duplicating their logic;
- return one coherent material-level result while preserving normalized inputs and selected/candidate fits;
- add `studies/joint-characterization/run_joint_material_characterization.m`;
- load completed tensile and compression MAT files without reprocessing raw data;
- allow experiment-specific paths, exclusions and output folders in the driver;
- export candidate summary, selected parameters, selected mode/specimen summaries, MAT persistence, Markdown report, and mode-specific PNG/FIG files;
- state explicitly that specimens are independent and unpaired;
- preserve A and B outputs without copying their complete bundles.

Planned outputs:

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

C4 must not add new constitutive models, unsupported experimental modes, or robustness alternatives that belong to C5.

## C5 — later robustness and extensibility audit

Audit mode weights, normalization, sampling density, specimen count, and deformation range. Add alternatives only when supported by evidence. Do not implement modes without real data and physical contracts.

## Deferred decisions

- single-mode consensus majority policy;
- Yeoh-2 as a separate registered model;
- Ogden or other additional models;
- real validation of two-study tensile comparison export;
- modes beyond tension and compression.

Do not combine these with C4.

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
