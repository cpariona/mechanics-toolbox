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

Configuration:

```matlab
config = mechanics.config.jointMaterialCharacterizationConfig();
```

Mode registry:

```matlab
mode = mechanics.workflow.jointCharacterizationModeRegistry(modeName);
```

Study normalization:

```matlab
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
```

The normalized result contains:

```text
normalized.modeNames
normalized.modeWeights
normalized.specimens
normalized.modeSummary
normalized.specimenCount
normalized.observationCount
normalized.config
normalized.createdAt
```

Each specimen contains mode, study and original identifiers, a namespaced global identifier, deformation, measured stress, constitutive context, units, and observation count.

C1:

- accepts unequal specimen counts;
- preserves negative compression signs;
- preserves original sampling grids;
- creates no synthetic pairing;
- maps engineering and true measures to the maintained constitutive context;
- validates units, measures, weights, observations, completed-study state, and supported modes.

## C2: implemented fixed-model joint fitting

Maintained fitting entrypoint:

```matlab
fit = mechanics.fitting.fitJointModel( ...
    normalized, modelName, config);
```

C2 fits one registered model to every normalized specimen using one common parameter vector.

### Hierarchical objective

For specimen `s`, the normalized loss is:

```text
mean((measuredStress - predictedStress).^2 / normalizationScale^2)
```

The initial normalization scale is the specimen response range:

```text
max(measuredStress) - min(measuredStress)
```

A configured positive floor is used when the response range is too small.

Specimen losses are averaged within each mode. Mode losses are then combined using explicit positive mode weights normalized to sum to one. Weights are resolved by configured mode name, not by input position.

Consequences:

- point count does not determine specimen influence;
- specimen count does not automatically determine mode influence;
- tension and compression have equal total influence by default;
- studies may be supplied in a different order without exchanging their configured weights.

### Reused fitting contracts

C2 reuses:

- `mechanics.models.modelRegistry`;
- `mechanics.models.evaluateModel`;
- `mechanics.fitting.resolveFitConfig`;
- initial-guess generation;
- bound transformations;
- multistart `fminsearch` configuration.

The joint objective is implemented separately because its specimen-mode hierarchy is not the same contract as pointwise individual fitting.

### C2 result

```text
fit.modelName
fit.parameterNames
fit.parameters
fit.objective
fit.exitFlag
fit.converged
fit.starts
fit.modeNames
fit.modeWeights
fit.specimens
fit.specimenSummary
fit.modeSummary
fit.normalization
fit.fitConfig
fit.config
fit.createdAt
```

Each fitted specimen retains predictions, residuals, and normalization scale.

The specimen summary reports observation count, physical RMSE, normalized RMSE, and maximum absolute error. The mode summary reports configured weight, specimen count, mean physical RMSE, mean normalized RMSE, and normalized loss.

### C2 validation

Synthetic Neo-Hookean tension and compression data verified:

- recovery of a known common parameter;
- unequal specimen counts;
- duplicate original identifiers across modes;
- different sampling densities;
- explicit and reordered mode weights;
- retained predictions and residuals;
- rejection of unsupported normalization and invalid weights.

Focused tests passed for:

```matlab
focusedResults = runtests([
    "tests/test_joint_fixed_model_fitting.m"
    "tests/test_joint_characterization_input_contract.m"
    "tests/test_constitutive_models.m"
]);
```

The complete repository suite also passed. `tests/test_model_fitting.m` is not a repository test file; attempting to run that path produces a suite-construction error and is not an implementation failure.

## C3: next phase

C3 will:

- fit every model listed in `config.candidateModelNames` using the C2 objective;
- retain candidate parameters, convergence, starts, joint objective, mode diagnostics, and specimen diagnostics;
- define joint eligibility and deterministic ranking explicitly;
- use practical fit equivalence and parsimony without altering individual selections from A and B;
- test failed candidates, ties, and generating-model recovery.

Adding a future constitutive model should require model registration and model-specific tests, not changes to joint orchestration.

## C4: driver and outputs

C4 will add:

```text
studies/joint-characterization/run_joint_material_characterization.m
```

It will load completed tension and compression MAT studies without reprocessing raw data and export:

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

## C5: robustness audit

C5 will audit sensitivity to mode weights, normalization, sampling density, and deformation range. Alternatives will only be added when evidence supports them. Unsupported experimental modes will not be implemented merely to demonstrate extensibility.
