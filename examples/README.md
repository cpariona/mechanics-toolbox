# Examples

This folder contains manual, user-facing scripts that demonstrate supported toolbox workflows.

## Naming

- `run_*.m` files are executable demonstrations. They are not automated tests.
- Automated assertions belong under `tests/` and use `test_*.m` filenames.
- Reusable implementation belongs under `src/+mechanics/` and must not be embedded in example scripts.
- Input templates belong under `examples/templates/`, not beside executable scripts.

## Maintained examples

### Experimental workflows

- `run_ecoflex_tensile_study.m`: complete workbook-to-report tensile workflow.
- `run_experimental_specimen.m`: import and process one generic specimen.
- `run_zwick_d412_extraction.m`: vendor-specific workbook extraction.
- `run_batch_processing.m`: process a specimen manifest.

### Constitutive workflows

- `run_hyperelastic_models.m`: evaluate registered constitutive models.
- `run_hyperelastic_fit.m`: fit one model to one dataset.
- `run_fit_diagnostics_workflow.m`: complete diagnostics for one fitted model.
- `run_reliability_aware_model_comparison.m`: compare candidate models with diagnostics.
- `run_robust_model_selection.m`: assess model stability across fitting windows.
- `run_batch_model_comparison.m`: compare models across multiple specimens.
- `run_constitutive_study_report.m`: aggregate comparison, population inference, and reporting.

### Population and group workflows

- `run_selected_parameter_population.m`: summarize selected parameters across specimens.
- `run_group_comparison.m`: compare general group-level metrics.
- `run_group_parameter_inference.m`: infer differences in selected constitutive parameters.

### Synthetic demonstration

- `run_synthetic_tension_analysis.m`: demonstrate processing on generated tension data.

Examples may write generated output under `results/`. They should not be used as release validation; use `run_all_tests.m` for that purpose.
