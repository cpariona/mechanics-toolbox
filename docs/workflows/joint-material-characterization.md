# Joint material characterization

## Purpose

Joint material characterization estimates one constitutive parameter set from independent experimental modes while preserving the maintained tension and compression studies and their individual model-selection results.

The first supported modes are uniaxial tension and uniaxial compression. Specimens are independent and unpaired. Additional modes remain deferred until a real physical contract and data exist.

## Design principles

- Consume completed, already processed studies.
- Preserve mode-specific signs, measures, units, contexts, and sampling grids.
- Balance specimens within modes and modes within the objective explicitly.
- Reuse the model registry and fitting infrastructure only where contracts match.
- Preserve individual-study and consensus outputs without duplication.
- Do not add wrappers, aliases, bridge files, or placeholder modes.

## Final planned workflow

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

Initial inputs use heterogeneous completed studies:

```matlab
studies = {tensileStudy, compressionStudy};
modeNames = ["tension"; "compression"];
config = mechanics.config.jointMaterialCharacterizationConfig();
```

The maintained driver remains planned for:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

## C1: implemented input contract

C1 introduced:

```matlab
config = mechanics.config.jointMaterialCharacterizationConfig();
mode = mechanics.workflow.jointCharacterizationModeRegistry(modeName);
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
```

The normalized result preserves mode, study and specimen identity, physical signs, original sampling grids, constitutive context, units, and observation counts. It accepts unequal specimen counts and creates no synthetic pairing.

## C2: implemented fixed-model joint fitting

Maintained fitting entrypoint:

```matlab
fit = mechanics.fitting.fitJointModel( ...
    normalized, modelName, config);
```

C2 fits one registered model to every normalized specimen using one common parameter vector.

### Hierarchical objective

For each specimen, the initial normalized loss is:

```text
mean((measuredStress - predictedStress).^2 / normalizationScale^2)
```

The initial normalization scale is the specimen response range with a configured positive floor. Specimen losses are averaged within each mode. Mode losses are then combined using explicit positive weights normalized to sum to one and resolved by configured mode name.

The result retains predictions, physical residuals, physical RMSE, normalized RMSE, maximum absolute error, mode summaries, specimen summaries, convergence metadata, and all multistart attempts.

## C3: implemented multi-model fitting and joint selection

Maintained selection entrypoint:

```matlab
result = mechanics.workflow.selectJointModel(normalized, config);
```

C3 fits every unique model listed in:

```matlab
config.candidateModelNames
```

through `mechanics.fitting.fitJointModel`. Candidate parameter names, bounds, evaluation functions, and parameter counts remain owned by the model registry.

### Candidate retention

Every candidate is retained, including failed candidates. A candidate record contains its status, fit when available, error identifier and message when unavailable, convergence, eligibility, objective, parameter count, physical SSE, observation count, AIC, BIC, and configured order.

One candidate failure does not interrupt the remaining candidates.

### Eligibility

A candidate is eligible when:

- its joint fit completed;
- its joint objective is finite;
- it converged when `config.selection.requireConvergence` is enabled.

If no candidate is eligible, selection fails explicitly rather than returning a partial material characterization.

### Practical equivalence and ranking

The best eligible joint objective defines a practical-equivalence threshold using:

```matlab
config.selection.practicalObjectiveTolerance
```

Eligible candidates inside that threshold are practically equivalent. Selection within the equivalent set follows:

1. fewer constitutive parameters;
2. lower exact joint objective;
3. deterministic configured order from `config.selection.tieBreakOrder`.

This preserves parsimony when a more complex nested model only improves the hierarchical objective marginally.

AIC and BIC are retained as physical residual diagnostics. They do not replace the hierarchical objective because they are based on the pooled physical SSE rather than the equal-specimen/equal-mode material objective.

### C3 result

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

The candidate summary contains:

```text
ModelName
Status
Converged
Eligible
PracticallyEquivalent
ParameterCount
Objective
PhysicalSSE
ObservationCount
AIC
BIC
ConfiguredOrder
```

The selected fit remains the complete C2 fit result, including parameters, predictions, residuals, specimen diagnostics, mode diagnostics, normalization and multistart results.

### C3 validation

Synthetic tests verified:

- Neo-Hookean selection by parsimony when nested candidates are practically equivalent;
- Yeoh selection and parameter recovery when nonlinear synthetic data require the higher-order model;
- retention and exclusion of a failed unknown candidate;
- deterministic configured ordering;
- rejection of duplicate candidates and invalid selection tolerance;
- finite AIC and BIC diagnostics.

Focused tests passed:

```matlab
focusedResults = runtests([
    "tests/test_joint_model_selection.m"
    "tests/test_joint_fixed_model_fitting.m"
    "tests/test_joint_characterization_input_contract.m"
    "tests/test_constitutive_models.m"
]);
```

The complete `run_all_tests()` suite also passed.

## C4: next phase — public workflow, driver and outputs

C4 will add the final orchestration entrypoint:

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

It will:

- normalize completed studies through C1;
- fit and select candidates through C3;
- expose one coherent material-level result;
- add the maintained driver at `studies/joint-characterization/run_joint_material_characterization.m`;
- load completed tensile and compression MAT studies without reprocessing raw data;
- export a nonredundant result bundle;
- generate separate joint-fit figures for each real mode.

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

C4 must not copy complete tensile or compression study bundles. It must preserve links to input studies and state that specimens are independent and unpaired.

## C5: robustness audit

C5 will audit sensitivity to mode weights, normalization, sampling density, specimen count, and deformation range. Alternatives will only be added when evidence supports them. Unsupported experimental modes will not be implemented merely to demonstrate extensibility.
