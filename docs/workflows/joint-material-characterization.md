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

## Maintained public workflow

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

Initial use accepts heterogeneous completed studies:

```matlab
studies = {tensileStudy, compressionStudy};
modeNames = ["tension"; "compression"];
config = mechanics.config.jointMaterialCharacterizationConfig();
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

The workflow composes the maintained C1 normalizer and C3 selector. It does not duplicate preprocessing, fitting, or ranking logic.

The returned result contains:

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

## C1: input contract

C1 introduced:

```matlab
config = mechanics.config.jointMaterialCharacterizationConfig();
mode = mechanics.workflow.jointCharacterizationModeRegistry(modeName);
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
```

The normalized result preserves mode, study and specimen identity, physical signs, original sampling grids, constitutive context, units, and observation counts. It accepts unequal specimen counts and creates no synthetic pairing.

## C2: fixed-model joint fitting

```matlab
fit = mechanics.fitting.fitJointModel( ...
    normalized, modelName, config);
```

C2 fits one registered model to every normalized specimen using one common parameter vector.

For each specimen, the initial normalized loss is:

```text
mean((measuredStress - predictedStress).^2 / normalizationScale^2)
```

The initial normalization scale is the specimen response range with a configured positive floor. Specimen losses are averaged within each mode. Mode losses are then combined using explicit positive weights normalized to sum to one and resolved by configured mode name.

The fit retains predictions, physical residuals, physical RMSE, normalized RMSE, maximum absolute error, mode summaries, specimen summaries, convergence metadata, and all multistart attempts.

## C3: multi-model fitting and joint selection

```matlab
selection = mechanics.workflow.selectJointModel(normalized, config);
```

Every unique model in `config.candidateModelNames` is fitted through `mechanics.fitting.fitJointModel`. Candidate parameter names, bounds, evaluation functions, and parameter counts remain owned by the model registry.

Every candidate is retained, including failures. Eligibility requires a completed finite fit and, when configured, convergence.

Practical equivalence is defined by `config.selection.practicalObjectiveTolerance`. Selection within the equivalent set follows:

1. fewer constitutive parameters;
2. lower exact joint objective;
3. deterministic configured order from `config.selection.tieBreakOrder`.

AIC and BIC are retained as pooled physical-residual diagnostics. They do not replace the hierarchical equal-specimen/equal-mode objective.

## C4: maintained driver and result bundle

The maintained driver is:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

It loads completed tensile and compression MAT studies, configures the joint workflow, executes the public entrypoint, and displays the selected model and summaries. It does not import raw workbooks or rerun the individual study workflows.

The maintained exporter is:

```matlab
outputFiles = mechanics.io.exportJointMaterialCharacterization( ...
    result, outputFolder);
```

The nonredundant bundle is:

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

The selected-parameter table is derived from the selected model registry definition and selected common parameter vector. Candidate, mode, and specimen tables preserve the C2-C3 diagnostics rather than recomputing them.

Mode figures are generated through:

```matlab
figureHandle = mechanics.plotting.plotJointModeFit(result, modeName);
```

Each figure contains the experimental observations and selected joint-model prediction for the specimens of one real mode. Additional figures are generated only when another real registered mode exists.

The Markdown report records:

- the selected model and common parameters;
- candidate eligibility and ranking diagnostics;
- per-mode and per-specimen fit summaries;
- links to mode-specific figures;
- the independent and unpaired nature of the input specimens;
- the distinction between the joint material result and the retained A/B study outputs.

The bundle does not copy the complete tensile or compression study exports.

## Validation

Focused tests passed for:

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

Synthetic end-to-end tests verified:

- C1-C3 composition through the public workflow;
- recovery and selection of a known common constitutive response;
- enabled and disabled export behavior;
- creation of all maintained CSV, MAT, Markdown, PNG, and FIG outputs;
- selected-parameter and report content;
- persisted MAT loading;
- rejection of incomplete export inputs.

Real joint execution remains pending until the available completed tensile and compression MAT files are selected and their driver paths are confirmed.

## C5: robustness and extensibility audit

C5 will audit sensitivity to mode weights, normalization, sampling density, specimen count, and deformation range. Alternatives will only be added when evidence supports them.

C5 must also verify that another real experimental mode can be added through the mode contract without editing unrelated fitting, selection, reporting, and export code. Unsupported modes must not be implemented merely to demonstrate extensibility.
