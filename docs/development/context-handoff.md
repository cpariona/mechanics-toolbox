# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Validated merged baseline

The current merged baseline is PR #40:

```text
d42bafe54e8fe884a0f6b282f827628c3c3906a6
```

It includes the maintained tension and compression workflows, individual model selection, consensus-model population analysis, study reporting, tensile-study comparison export, C1 joint input normalization, C2 fixed-model joint fitting, and C3 multi-model joint selection.

## Active branch and scope

```text
feature/joint-characterization-driver-outputs
```

This branch implements C4 only: the public joint-characterization workflow, maintained driver, mode plotting, and nonredundant result bundle.

Focused C4 tests and the complete `run_all_tests()` suite passed.

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

## C3 — completed

Implemented:

```matlab
selection = mechanics.workflow.selectJointModel(normalized, config);
```

C3:

- fits every unique model in `config.candidateModelNames` through `fitJointModel`;
- retains completed and failed candidates;
- defines eligibility from completed finite fits and optional convergence requirements;
- defines practical equivalence from `config.selection.practicalObjectiveTolerance`;
- selects the lowest-parameter equivalent model;
- breaks remaining ties by exact joint objective and `config.selection.tieBreakOrder`;
- retains pooled physical SSE, AIC, and BIC as diagnostics;
- preserves the complete selected C2 fit.

## C4 — implemented on the active branch

Public workflow:

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

C4 composes the C1 normalizer and C3 selector. It returns:

```text
result.modeNames
result.modeWeights
result.specimens
result.modeInputSummary
result.candidates
result.candidateSummary
result.selectedModelName
result.selectedFit
result.modeSummary
result.specimenSummary
result.selection
result.config
result.createdAt
result.outputFiles
```

Maintained driver:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

The driver loads completed tensile and compression MAT studies, configures the joint workflow, and exports results. It does not import raw data or rerun the individual studies.

Maintained exporter:

```matlab
outputFiles = mechanics.io.exportJointMaterialCharacterization( ...
    result, outputFolder);
```

Maintained plotting entrypoint:

```matlab
figureHandle = mechanics.plotting.plotJointModeFit(result, modeName);
```

Output bundle:

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

The bundle preserves joint candidate, selected-model, mode, and specimen diagnostics without copying the complete A/B study bundles. Reports state explicitly that tension and compression specimens are independent and unpaired.

## C4 validation

Focused tests passed:

```matlab
focusedResults = runtests([
    "tests/test_joint_material_characterization_workflow.m"
    "tests/test_joint_model_selection.m"
    "tests/test_joint_fixed_model_fitting.m"
    "tests/test_joint_characterization_input_contract.m"
    "tests/test_constitutive_models.m"
]);
```

The complete `run_all_tests()` suite also passed.

Synthetic end-to-end validation covered workflow composition, known-response recovery, export enable/disable behavior, CSV/MAT/Markdown/PNG/FIG creation, selected-parameter content, persisted MAT loading, and invalid export inputs.

Real joint execution remains pending. Before running the maintained driver, confirm the actual completed MAT paths for the tensile and compression studies.

## C5 — next objective

C5 is a limited robustness and extensibility audit. It must evaluate:

- sensitivity to configured mode weights;
- response-range normalization behavior;
- sampling-density changes;
- unequal specimen counts;
- deformation-range differences;
- whether a real future mode can be added through the mode registry without editing unrelated fitting, selection, plotting, reporting, and export code.

Alternative weighting or normalization strategies must only be added when evidence supports them. Do not add unsupported experimental modes.

## Deferred decisions

- single-mode consensus majority policy;
- Yeoh-2 as a separate registered model;
- Ogden or other additional models;
- real validation of two-study tensile comparison export;
- modes beyond tension and compression.

Do not combine these with C5 unless directly required by evidence from the robustness audit.

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
