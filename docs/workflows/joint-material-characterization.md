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

## Robustness audit

```matlab
auditConfig = mechanics.config.jointCharacterizationAuditConfig();
robustnessAudit = mechanics.workflow.auditJointMaterialCharacterization( ...
    normalized, config, auditConfig);
```

The maintained driver stores the audit result as `robustnessAudit`. The audit is one-factor-at-a-time and evaluates mode weights, sampling density, retained deformation range, and specimens retained per mode. It does not form a Cartesian product of perturbations or add alternative normalization methods without evidence.

## Real-data result

The first maintained real run used four tensile and four compression specimens, with 22,006 observations in total. Yeoh was selected with:

```text
C10 = 0.0524808 MPa
C20 = 1.98662e-4 MPa
C30 = 4.04826e-6 MPa
```

The joint objective was approximately `9.3633e-4`. Neo-Hookean and Mooney-Rivlin had objectives of approximately `1.6832e-2`, so Yeoh was not selected by a marginal difference.

Mean normalized RMSE was approximately:

```text
tension:     3.94 %
compression: 1.66 %
```

The response was therefore represented more accurately in compression, while the common parameter set still captured the nonlinear tensile trend across independent specimens.

## Real-data robustness result

Yeoh remained selected in every configured scenario:

| Scenario | Objective | Relative parameter change |
|---|---:|---:|
| Baseline | 0.00093633 | 0 |
| Tension-weighted | 0.0012154 | 0.022449 |
| Compression-weighted | 0.00061859 | 0.0079484 |
| 50% sampling density | 0.00093796 | 0.00011288 |
| 75% deformation range | 0.0016051 | 0.011781 |
| One specimen per mode | 0.00067871 | 0.0086765 |

The largest parameter-vector change was approximately `2.25 %`, under asymmetric mode weighting. Halving the sampling density changed parameters by approximately `0.011 %`, indicating that point density was not driving the fitted material response. Model identity was stable even when only one specimen per mode was retained.

These results support the current equal-specimen, equal-mode, response-range-normalized contract for this dataset. They do not establish universal optimality for other materials or experiments.

## Validation

Focused joint-characterization tests and the complete `run_all_tests()` suite passed after introducing the sign tolerance. Tests verify that small scale-relative opposite-sign stress noise is retained, while material sign violations are still rejected.

## Extension policy

A future experimental mode may be added only when real data and a physical contract exist. It should use the mode registry and normalized specimen contract without requiring unrelated changes to fitting, selection, plotting, reporting, or export code.

New constitutive models remain model-registry responsibilities. Joint orchestration should not add model-name conditionals where the registered contract is sufficient.
