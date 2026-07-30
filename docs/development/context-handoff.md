# Context handoff

Use this document as the persistent starting point for future repository work.

## Repository

```text
cpariona/mechanics-toolbox
```

Do not modify `main`, open a pull request, or merge changes unless explicitly requested.

## Validated merged baseline

The current merged baseline is PR #41:

```text
1104d05c2c4ee76ce26f875570654f1f998bc4d2
```

It includes the maintained tension and compression workflows, individual model selection, consensus-model population analysis, study reporting, tensile-study comparison export, and C1-C4 joint material characterization.

## Active branch and scope

```text
audit/joint-characterization-robustness
```

This branch implements C5 only: a controlled robustness audit for the completed joint-characterization workflow and an optional audit section in the maintained driver.

Focused C5 tests and the complete `run_all_tests()` suite passed.

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

### C1 — completed

```matlab
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
```

C1 consumes completed studies, preserves physical signs and sampling grids, accepts unequal specimen counts, namespaces duplicate identifiers, maps measures to model contexts, validates units and weights, and creates no synthetic pairing.

### C2 — completed

```matlab
fit = mechanics.fitting.fitJointModel( ...
    normalized, modelName, config);
```

C2 fits one registered model using one common parameter vector. It computes a response-range-normalized loss per specimen, averages specimen losses within each mode, and combines mode losses using explicit positive weights resolved by mode name.

C2 retains predictions, physical residuals, physical and normalized RMSE, maximum absolute error, mode and specimen summaries, convergence metadata, and multistart results.

### C3 — completed

```matlab
selection = mechanics.workflow.selectJointModel(normalized, config);
```

C3 fits all configured registered models, retains completed and failed candidates, defines eligibility and practical equivalence, prefers parsimonious equivalent models, and preserves pooled SSE, AIC, and BIC as diagnostics rather than replacements for the hierarchical objective.

### C4 — completed

Public workflow:

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

Maintained driver:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

Maintained exporter:

```matlab
outputFiles = mechanics.io.exportJointMaterialCharacterization( ...
    result, outputFolder);
```

C4 provides the public orchestration workflow, one mode-specific selected-fit figure per real mode, and the nonredundant MAT/CSV/Markdown/PNG/FIG bundle. It does not copy the complete A/B study exports.

### C5 — implemented on the active branch

Configuration:

```matlab
auditConfig = mechanics.config.jointCharacterizationAuditConfig();
```

Workflow:

```matlab
audit = mechanics.workflow.auditJointMaterialCharacterization( ...
    normalized, config, auditConfig);
```

C5 performs a one-factor-at-a-time audit of:

- configured mode weights;
- sampling density;
- retained deformation range;
- specimens retained per mode.

The default audit contains one baseline and limited perturbations. It does not form a Cartesian product of scenarios and does not add alternative normalization methods without evidence.

The result contains the complete baseline and scenario results plus:

```text
audit.scenarioSummary
```

with scenario name, perturbation type, selected model, objective, model agreement with baseline, relative parameter change where physically comparable, specimen count, and observation count.

The maintained driver exposes the audit through an optional `runRobustnessAudit` section. No second driver was added.

## C5 validation

Focused tests passed:

```matlab
focusedResults = runtests([
    "tests/test_joint_characterization_robustness.m"
    "tests/test_joint_material_characterization_workflow.m"
    "tests/test_joint_model_selection.m"
    "tests/test_joint_fixed_model_fitting.m"
    "tests/test_joint_characterization_input_contract.m"
]);
```

The complete `run_all_tests()` suite also passed.

Synthetic validation covered known-parameter stability, asymmetric mode weights, reduced sampling density, reduced deformation range, reduced specimen count, input immutability, and invalid audit configuration.

## Current status after C5

The planned C1-C5 implementation is complete in code and synthetic tests.

Still pending:

- merge of the active C5 pull request;
- confirmation of actual completed tensile and compression MAT paths;
- one real joint-characterization run;
- interpretation of robustness results on real data;
- real validation of the two-study tensile comparison export.

No additional implementation phase should be started automatically after C5. The next repository action should be selected from evidence obtained during real execution or from a separately approved model/workflow objective.

## Deferred decisions

- single-mode consensus majority policy;
- Yeoh-2 as a separate registered model;
- Ogden or other additional models;
- modes beyond tension and compression;
- alternative joint normalization or weighting strategies;
- cross-validation or fitting-window sensitivity.

Do not implement these without a limited approved phase and supporting need.

## Extension policy

A future experimental mode may be added only when real data and a physical contract exist. Extension should use the mode registry and normalized specimen contract without editing unrelated fitting, selection, plotting, reporting, and export code.

A future constitutive model should be added through the model registry and model-specific tests. Joint orchestration should not add model-name conditionals where the registry contract is sufficient.

## Validation protocol

For each future phase:

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
