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

These fields drive tables, reports, and figure labels.

- model parameters and `mu0` use the stress unit;
- normalization scale, RMSE, and maximum absolute error use the stress unit;
- deformation limits use the strain unit;
- normalized objective, normalized RMSE, and normalized loss are dimensionless;
- labels distinguish engineering/true strain and nominal/Cauchy stress.

`mechanics.plotting.mechanicalAxisLabel` owns the shared label contract and is used by both application-range and joint-characterization plots.

## Maintained figures

### Tensile fit and residuals

```matlab
mechanics.plotting.plotTensileApplicationRangeFit(result)
```

The upper panel compares measured and selected-model stress for every retained tensile specimen. The lower panel shows:

```text
residual = measured stress - predicted stress
```

against deformation.

### Range sensitivity

```matlab
mechanics.plotting.plotTensileApplicationRangeSensitivity(result)
```

The figure shows `mu0` and normalized objective versus the upper fitted deformation limit, with selected-model annotations.

### Compression validation

```matlab
mechanics.plotting.plotTensileApplicationRangeCompressionValidation(result)
```

The figure is available only when compression validation exists. It compares measured and fixed-parameter predictions and shows residuals versus deformation. The title states that no refitting occurred.

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

CSV files add explicit unit columns for physical quantities. Complete curves, predictions, residuals, candidates, and scenario evidence remain in the MAT result rather than being duplicated into curve CSV files. The Markdown report embeds the PNG figures.

## Compression boundary

Compression remains external validation only:

```matlab
validation.refitPerformed = false;
```

Compression cannot influence tensile fitting, eligibility, or model selection.

## Validation status

The pre-figure D1-D5 implementation passed all focused tests and `run_all_tests()` according to the user.

The figure and unit-export additions still require local MATLAB validation. Required checks:

1. run `tests/test_tensile_application_range_figures.m`;
2. run `tests/test_tensile_application_range_workflow.m`;
3. run joint-characterization plotting/export tests affected by the shared label helper;
4. run `run_all_tests()`;
5. regenerate and inspect all real PNG, FIG, CSV, MAT, and Markdown artifacts;
6. run `git diff --check` and verify no generated files are tracked.
