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

The workflow composes the maintained input normalizer and joint selector. It does not duplicate preprocessing, fitting, or ranking logic.

The returned result contains normalized specimens, candidate fits, the selected model and fit, mode and specimen summaries, selection metadata, configuration, creation time, and exported files.

## C1: input contract

```matlab
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

For each specimen, the normalized loss is:

```text
mean((measuredStress - predictedStress).^2 / normalizationScale^2)
```

The normalization scale is the specimen response range with a configured positive floor. Specimen losses are averaged within each mode. Mode losses are then combined using explicit positive weights normalized to sum to one and resolved by configured mode name.

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

The bundle preserves joint candidate, selected-model, mode, and specimen diagnostics without copying the complete tensile or compression study exports. Reports state explicitly that tension and compression specimens are independent and unpaired.

## C5: robustness audit

Configuration:

```matlab
auditConfig = mechanics.config.jointCharacterizationAuditConfig();
```

Workflow:

```matlab
audit = mechanics.workflow.auditJointMaterialCharacterization( ...
    normalized, config, auditConfig);
```

The audit is one-factor-at-a-time. It evaluates one baseline and independent perturbations of:

- configured mode weights;
- sampling density;
- retained deformation range;
- specimens retained per mode.

The default scenarios are:

```matlab
auditConfig.modeWeightSets = [
    1, 1
    3, 1
    1, 3
];
auditConfig.samplingFractions = [1; 0.5];
auditConfig.deformationFractions = [1; 0.75];
auditConfig.specimensPerMode = [Inf; 1];
```

The audit deliberately does not form a Cartesian product of perturbations. Each result remains attributable to one changed factor and the computational cost remains bounded.

The response-range normalization contract is preserved. C5 does not add alternative normalizations merely to demonstrate configurability.

The returned audit contains:

```text
audit.baseline
audit.scenarios
audit.scenarioSummary
audit.config
audit.auditConfig
audit.createdAt
```

The scenario summary reports:

```text
Scenario
Perturbation
SelectedModel
Objective
SameModelAsBaseline
ParameterRelativeChange
SpecimenCount
ObservationCount
```

`ParameterRelativeChange` is reported only when the selected model is unchanged. Parameters from different constitutive models are not compared as if they had the same physical meaning.

The maintained driver exposes the audit as an optional section through `runRobustnessAudit`. A second driver is not maintained.

## Validation

Focused tests passed for:

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

Synthetic validation covers:

- known common-parameter recovery;
- asymmetric mode weights;
- reduced sampling density;
- reduced deformation range;
- reduced specimen count;
- preservation of the normalized input;
- invalid sampling and mode-weight configuration.

Real joint execution and real-data robustness interpretation remain pending until completed tensile and compression MAT files are selected and their driver paths are confirmed.

## Extension policy

A future experimental mode may be added only when real data and a physical contract exist. Extension should occur through the mode registry and normalized specimen contract. Unsupported modes are not implemented as placeholders.

New constitutive models remain model-registry responsibilities. Joint orchestration, ranking, reporting, and robustness code should not require model-name branches when the registered contract is sufficient.
