# Joint material characterization

## Purpose

Joint material characterization estimates one constitutive parameter set from independent uniaxial tension and compression studies while preserving the maintained single-mode workflows and their outputs. Specimens are independent and unpaired.

## Maintained workflow

```matlab
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, modeNames, config);
```

The workflow composes input normalization, fixed-model joint fitting, multi-model selection, plotting, reporting, and export without duplicating the underlying contracts.

## Input normalization and sign validation

```matlab
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, modeNames, config);
```

The normalized result preserves study and specimen identity, original sampling grids, units, measures, contexts, physical signs, and unequal specimen counts. It creates no synthetic pairing.

Real tensile data contained isolated negative stresses near the zero reference. These values were between approximately `-4.3e-5` and `-2.0e-4 MPa`, while specimen maxima were approximately `1.49-1.73 MPa`. They are treated as acquisition or zero-reference noise rather than physical compression.

Sign validation uses configurable scale-aware tolerances:

```matlab
config.signTolerance.deformationRelative = 1e-8;
config.signTolerance.stressRelative = 1e-3;
config.signTolerance.absolute = 100 * eps;
```

The tolerance is used only to validate the stored sign convention. Observations are not clipped, zeroed, removed, or otherwise changed before fitting. Larger sign violations remain errors.

## Joint objective

For each specimen, the normalized loss is:

```text
mean((measuredStress - predictedStress).^2 / normalizationScale^2)
```

The normalization scale is the specimen response range with a positive floor. Specimen losses are averaged within each mode and mode losses are combined using explicit positive mode weights normalized to sum to one. This prevents the much denser tensile acquisition from dominating compression solely through observation count.

## Model fitting and selection

```matlab
fit = mechanics.fitting.fitJointModel(normalized, modelName, config);
selection = mechanics.workflow.selectJointModel(normalized, config);
```

All configured registered models are fitted. Failed and completed candidates are retained. Eligible practically equivalent candidates are ranked by parameter count, exact joint objective, and deterministic configured order. Pooled physical SSE, AIC, and BIC remain diagnostics rather than replacements for the hierarchical objective.

The library default candidate set remains:

```text
neo-hookean
mooney-rivlin
yeoh-third-order
```

The maintained real joint-characterization driver explicitly compares:

```text
neo-hookean
mooney-rivlin
yeoh-second-order
yeoh-third-order
```

Both Yeoh variants share:

```text
familyName = yeoh
functionHandle = mechanics.models.yeoh
mu0 = 2 * C10
```

Their registered contracts are:

```text
yeoh-second-order -> C10, C20       -> order 2
yeoh-third-order  -> C10, C20, C30  -> order 3
```

The bare identifier `yeoh` is not a registered model identity and is not retained as a compatibility alias. Human-facing outputs use `Yeoh second order` and `Yeoh third order`; MAT/CSV results persist the canonical registered identifiers.

## Maintained driver and bundle

```text
studies/joint-characterization/run_joint_material_characterization.m
```

The driver consumes:

```text
results/real-tensile-study/tensile_study.mat
results/real-compression-study/compression_study.mat
```

Each MAT file contains one completed study variable named `study`.

The maintained result bundle is:

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

The bundle does not duplicate the complete tension and compression exports.

Generated results that still contain the historical third-order identifier `yeoh` are pre-migration snapshots. Regenerate them with the current drivers when they must be consumed by current code; do not add a legacy registry alias.

## Robustness audit

```matlab
auditConfig = mechanics.config.jointCharacterizationAuditConfig();
robustnessAudit = mechanics.workflow.auditJointMaterialCharacterization( ...
    normalized, config, auditConfig);
```

The maintained driver stores the audit result as `robustnessAudit`. The audit is one-factor-at-a-time and evaluates mode weights, sampling density, retained deformation range, and specimens retained per mode. It does not form a Cartesian product of perturbations or add alternative normalization methods without evidence.

## Final real-data evidence

The final four-candidate run after the explicit-order identifier migration used four tensile and four compression specimens and 22,006 observations. The candidate objectives were approximately:

```text
Neo-Hookean       0.016832
Mooney-Rivlin     0.016832
Yeoh second order 0.00124659
Yeoh third order  0.000936332
```

Third-order Yeoh remained selected. The fitted shared parameters were approximately:

```text
C10 = 0.052481 MPa
C20 = 1.99e-4 MPa
C30 = 4e-6 MPa
```

The corresponding pooled diagnostics for third-order Yeoh were approximately:

```text
Physical SSE = 81.8727
AIC          = -123093
BIC          = -123069
```

Mean normalized RMSE remained approximately:

```text
tension:     3.94 %
compression: 1.66 %
```

These values match the pre-rename four-candidate run to the inspected precision. The final migration therefore changed persisted model identity from the historical `yeoh` string to `yeoh-third-order` without changing the scientific conclusion or constitutive result.

## Validation

The user reported successful local execution of all focused migration tests and the complete `run_all_tests()` suite after the explicit-order identity migration.

The maintained joint driver was then regenerated successfully. The final bundle contains canonical `yeoh-second-order` and `yeoh-third-order` identities, human-facing `Yeoh second order` / `Yeoh third order` labels, finite registry-derived `mu0` values, and the same selected third-order Yeoh conclusion observed before the identifier rename.

## Extension policy

A future experimental mode may be added only when real data and a physical contract exist. It should use the mode registry and normalized specimen contract without requiring unrelated changes to fitting, selection, plotting, reporting, or export code.

New constitutive models remain model-registry responsibilities. Joint orchestration should not add model-name conditionals where the registered contract is sufficient.
