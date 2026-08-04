# Tensile application-range characterization

## Status

D1-D5 are implemented. The active figures branch adds unit-aware visualization and export after inspection of the real tensile and compression results.

## Public workflow

```matlab
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config, compressionStudy);
```

The workflow composes maintained normalization, fitting, selection, sensitivity, optional compression validation, and export contracts without re-importing raw data.

## Library defaults and real driver

Library defaults remain conservative:

```matlab
config.fitRange = [0, 0.30];
config.rangeSensitivity.maximumDeformations = [0.20; 0.25; 0.30];
```

The maintained real-study driver explicitly requests the extended analysis:

```matlab
config.fitRange = [0, 0.50];
config.rangeSensitivity.maximumDeformations = [0.30; 0.40; 0.50];
```

This keeps the general API stable while recording the experiment-specific range decision in the driver.

## Units contract

Units and constitutive measures come from completed processed studies:

```text
specimen.StrainUnit
specimen.StressUnit
specimen.Context.deformationMeasure
specimen.Context.stressMeasure
```

Stored dimensionless strain units such as `1`, `-`, or `dimensionless` are presented in all human-facing outputs as:

```text
mm/mm
```

This is a display convention only; it does not rescale deformation values. The shared utility is:

```matlab
mechanics.plotting.mechanicalDisplayUnit
```

It is consumed by `mechanicalAxisLabel` and by application-range export. Joint-characterization plots use the same axis-label contract.

- model parameters and `mu0` use the stress unit;
- normalization scale, RMSE, and maximum absolute error use the stress unit;
- deformation limits use `mm/mm` for dimensionless strain;
- normalized objective, normalized RMSE, and normalized loss use the display unit `[-]`;
- labels distinguish engineering/true strain and nominal/Cauchy stress.

## Maintained figures

### Tensile fit and residuals

```matlab
mechanics.plotting.plotTensileApplicationRangeFit(result)
```

The upper panel contains one measured curve per retained specimen and one shared selected-model prediction. The shared prediction is evaluated once over the complete retained tensile domain because all specimens use the same fitted parameter vector and constitutive context.

The lower panel recomputes, for every specimen:

```text
residual = measured stress - shared prediction
```

at that specimen's deformation observations. Its vertical label is intentionally concise (`Residual [stress unit]`); the complete convention remains in the panel title.

### Range sensitivity

```matlab
mechanics.plotting.plotTensileApplicationRangeSensitivity(result)
```

The figure shows `mu0` and normalized objective versus the upper fitted deformation limit. When one model is selected for every scenario, its name appears once in the title instead of being repeated at every point. Vertical labels are shortened to `mu0 [stress unit]` and `Objective [-]`.

### Compression validation

```matlab
mechanics.plotting.plotTensileApplicationRangeCompressionValidation(result)
```

The upper panel contains one measured curve per compression specimen and one shared tensile-calibrated prediction. The title states that no refitting occurred.

Because compression stresses are negative under the maintained sign convention, the diagnostic lower panel uses the magnitude residual:

```text
|measured stress| - |shared prediction|
```

A positive value therefore indicates that the tensile-calibrated model underpredicts the measured compressive-stress magnitude. Its vertical label is shortened to `Magnitude residual [stress unit]`, while the full definition remains in the panel title.

All maintained two-panel figures use a looser vertical tile spacing to prevent titles and vertical labels from overlapping.

## Export

Enabled export writes:

```text
candidate_model_summary.csv
selected_parameters.csv
reference_properties.csv
tensile_specimen_fit_summary.csv
range_sensitivity_summary.csv
compression_validation_summary.csv   % optional
tensile_fit_and_residuals.png
tensile_fit_and_residuals.fig
range_sensitivity.png
range_sensitivity.fig
compression_validation.png            % optional
compression_validation.fig            % optional
tensile_application_range_characterization.mat
tensile_application_range_characterization.md
```

CSV files add explicit unit columns for physical quantities. Dimensionless strain is written as `mm/mm`. Complete curves, predictions, signed stored residuals, candidates, and scenario evidence remain in the MAT result rather than being duplicated into curve CSV files. The Markdown report embeds the PNG figures and states the compression-figure residual convention explicitly.

## Compression boundary

Compression remains external validation only:

```matlab
validation.refitPerformed = false;
```

Compression cannot influence tensile fitting, eligibility, or model selection. The change in figure residual convention does not alter stored validation metrics, RMSE, predictions, fitting, or selection.

## Validation status

The user reported that the figure tests and complete repository suite passed before the final compact-label adjustment.

The final label and spacing corrections require local MATLAB validation. Required checks:

1. run `tests/test_tensile_application_range_figures.m`;
2. run `tests/test_tensile_application_range_workflow.m`;
3. run joint-characterization plotting/export tests affected by the shared label helper;
4. run `run_all_tests()`;
5. regenerate and inspect all real PNG, FIG, CSV, MAT, and Markdown artifacts;
6. run `git diff --check` and verify no generated files are tracked.
