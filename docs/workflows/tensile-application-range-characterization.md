# Tensile application-range characterization

## Status

The capability is implemented, merged on `main`, validated locally in MATLAB, and exercised with the maintained real-study driver.

The maintained workflow includes normalization, shared candidate fitting, parsimonious model selection, registry-derived reference properties, fit-range sensitivity, optional fixed-parameter compression validation, unit-aware figures, and export.

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

Stored dimensionless strain units such as `1`, `-`, or `dimensionless` are presented in human-facing outputs as:

```text
mm/mm
```

This is a display convention only; it does not rescale deformation values.

Shared utilities:

```matlab
mechanics.plotting.mechanicalDisplayUnit
mechanics.plotting.mechanicalAxisLabel
```

Presentation rules:

- model parameters and `mu0` use the stored stress unit;
- normalization scale, RMSE, and maximum absolute error use the stress unit;
- deformation limits use `mm/mm` for dimensionless strain;
- normalized objective, normalized RMSE, and normalized loss use `[-]`;
- labels distinguish engineering/true strain and nominal/Cauchy stress where metadata is available.

## Maintained figures

### Tensile fit and residuals

```matlab
mechanics.plotting.plotTensileApplicationRangeFit(result)
```

The upper panel contains one measured curve per retained specimen and one shared selected-model prediction. The shared prediction is evaluated over the complete retained tensile domain because all specimens use the same fitted parameter vector and constitutive context.

The lower panel recomputes, for every specimen:

```text
residual = measured stress - shared prediction
```

at that specimen's deformation observations. The vertical label is concise (`Residual [stress unit]`); the complete convention remains in the panel title.

### Range sensitivity

```matlab
mechanics.plotting.plotTensileApplicationRangeSensitivity(result)
```

The figure shows `mu0` and normalized objective versus the upper fitted deformation limit. When one model is selected for every scenario, its name appears once in the title. Vertical labels are shortened to `mu0 [stress unit]` and `Objective [-]`.

### Compression validation

```matlab
mechanics.plotting.plotTensileApplicationRangeCompressionValidation(result)
```

The upper panel contains one measured curve per compression specimen and one shared tensile-calibrated prediction. The title states that no refitting occurred.

Because compression stresses are negative under the maintained sign convention, the diagnostic lower panel uses:

```text
|measured stress| - |shared prediction|
```

A positive value indicates that the tensile-calibrated model underpredicts measured compressive-stress magnitude. The vertical label is concise (`Magnitude residual [stress unit]`), while the complete definition remains in the title.

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

CSV files include explicit unit columns for physical quantities. Dimensionless strain is written as `mm/mm`. Complete curves, predictions, signed stored residuals, candidates, and scenario evidence remain in the MAT result rather than being duplicated into curve CSV files. The Markdown report embeds the PNG figures and states the compression-figure residual convention explicitly.

## Compression boundary

Compression remains external validation only:

```matlab
validation.refitPerformed = false;
```

Compression cannot influence tensile fitting, eligibility, or model selection. The figure residual convention does not alter stored validation metrics, RMSE, predictions, fitting, or selection.

## Real-study result

The maintained driver selected `mooney-rivlin` for the inspected real tensile study.

Observed values were approximately:

```text
C10 = 0.0231222
C01 = 0.0054067
mu0 = 0.0570579
```

in the stored stress unit.

The selected model remained stable across upper deformation limits `0.30`, `0.40`, and `0.50`. The corresponding `mu0` variation was small, while compression prediction systematically underpredicted compressive-stress magnitude. This supports the tensile characterization and limits direct quantitative tension-to-compression transfer.

## Validation status

The user reported successful local execution after the final figure and label corrections:

```text
tests/test_tensile_application_range_figures.m
tests/test_tensile_application_range_workflow.m
run_all_tests()
```

The real-study driver was rerun and the final tensile, sensitivity, and compression figures were visually inspected and accepted.

## Maintenance boundary

Future maintenance should preserve:

- the completed-study input contract;
- one shared constitutive parameter vector across retained tensile specimens;
- compression as fixed-parameter external validation;
- stored physical values and signs;
- unit presentation as a display concern rather than numerical conversion;
- distinct ownership between individual tensile, compression, joint-characterization, and application-range workflows.
