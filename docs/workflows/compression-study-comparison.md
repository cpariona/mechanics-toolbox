# Compression study comparison

## Purpose

Completed compression studies can be compared without re-importing or reprocessing raw workbooks.

Public entrypoint:

```matlab
comparison = mechanics.workflow.compareCompressionStudies( ...
    studies, groupLabels, config);
```

The workflow delegates shared uniaxial study combination to `mechanics.workflow.compareUniaxialStudies` and group-level population inference to `mechanics.workflow.analyzeGroupComparison`.

The maintained Ecoflex material-comparison driver is:

```text
studies/compression/run_compression_material_comparison.m
```

It currently compares completed ASTM D575 studies for Ecoflex 00-20 and Ecoflex 00-50.

## Input boundary

The comparison consumes completed `compression_study.mat` results. It does not own workbook extraction, cycle selection, zero referencing, mechanical conversion, fitting, or specimen exclusion.

The two studies must use compatible stored strain/stress measures and units when the corresponding compatibility checks remain enabled.

## Pairwise stress-strain comparison

For exactly two groups, the maintained population comparison retains:

```text
mean stress for group A
mean stress for group B
pointwise bootstrap confidence interval for each group mean
mean signed difference A - B
pointwise bootstrap confidence interval for the difference
```

The upper panel of `group_comparison` shows both group mean stress-strain curves with their own 95% bootstrap confidence bands over the common strain range.

For compression studies the maintained stored stress convention is negative. The lower panel therefore presents the same stored difference as the physically intuitive magnitude convention:

```text
|stress_B| - |stress_A|
```

under the maintained negative-compression sign contract. Positive plotted values mean that group B has the larger compressive-stress magnitude.

This is a presentation convention only. Stored stress values and the statistical comparison remain unchanged.

Axes use the retained mechanics metadata so dimensionless engineering strain is displayed as `mm/mm` and stress-like quantities retain the stored stress unit.

The exported `pairwise_curve_comparison.csv` contains the mean and confidence limits for group A, group B, and their pairwise difference.

## Tangent-modulus comparison

When both group populations contain completed tangent-modulus aggregation, the exporter creates:

```text
group_tangent_modulus_comparison.png
group_tangent_modulus_comparison.fig
```

The figure overlays the population tangent-modulus curves and their available confidence bands over the common tangent-modulus strain range.

Each material also receives a horizontal model-derived initial shear reference $\mu_0$ when selected-model parameters are available. The value is obtained through the maintained registry-derived contract in `mechanics.statistics.deriveInitialShearModulus`; the plotting layer does not implement model-specific formulas.

Each dashed reference line is annotated directly on the figure with a LaTeX-formatted value such as:

```text
mu_0 = 0.113 MPa
```

The legend keeps the model-reference labels compact; the exact numerical values remain attached to the dashed lines themselves.

The reference uses the same population central statistic (`mean` or `median`) configured for the group population.

$\mu_0$ and tangent modulus have the same stress units but are not the same mechanical quantity:

- tangent modulus is a local incremental slope of the measured compression response;
- $\mu_0$ is a model-derived small-strain shear reference from the selected specimen fits.

The horizontal line is therefore a global stiffness reference, not a prediction of the tangent-modulus curve.

The associated summary is persisted as:

```text
group_model_initial_shear_modulus.csv
```

The summary records group name, contributing specimen count, central statistic, $\mu_0$, unit, and selected model names represented in the group.

## Specimen-level metric comparison

For exactly two groups the exporter also creates:

```text
group_metric_comparison.png
group_metric_comparison.fig
```

The figure shows individual processed-specimen values together with the group mean for each maintained scalar comparison metric:

```text
MaximumStrain
MaximumStress
MedianTangentModulus
```

Presentation uses concise human-readable panel titles:

```text
Maximum strain
Maximum stress
Median tangent modulus
```

The A-minus-B mean difference and bootstrap 95% interval are shown as a compact in-panel annotation rather than being concatenated into the title. Individual points remain visible because small experimental groups should not be represented only by aggregate bars or intervals.

## Maintained Markdown report

Every exported group comparison also creates:

```text
group_comparison_report.md
```

The report follows the maintained repository presentation style and includes:

- comparison group names and specimen counts;
- strain/stress measures and display units;
- scalar metric comparison with units and bootstrap intervals;
- model-derived initial shear summary;
- an explicit note distinguishing $\mu_0$ from tangent modulus;
- the compression magnitude-difference convention;
- an adaptive `Interpretation boundaries` section;
- embedded maintained PNG figures;
- reproducibility notes pointing to the stored configuration and MAT result.

The interpretation section follows the same boundary-oriented reporting pattern used by other maintained reports. It is generic rather than Ecoflex-specific: for each scalar metric it states whether the bootstrap interval for the A-minus-B mean difference includes zero and, when it does not, records the observed direction of the group difference. It does not label interval exclusion of zero as a formal hypothesis-test significance result.

When two finite positive model-derived $\mu_0$ summaries are available, the report also records their ratio as a constitutive stiffness reference while explicitly warning that the ratio is not a pointwise tangent-modulus ratio.

The report consumes the already computed comparison result and exported figures. It does not re-run statistics or reprocess source studies.

## Export bundle

The group comparison exporter produces:

```text
group_summary.csv
pairwise_curve_comparison.csv
pairwise_metric_comparison.csv
group_model_initial_shear_modulus.csv
group_comparison.png
group_comparison.fig
group_metric_comparison.png
group_metric_comparison.fig
group_tangent_modulus_comparison.png      % when available
group_tangent_modulus_comparison.fig      % when available
group_comparison.mat
group_comparison_report.md
```

Each group also retains its own population-analysis export folder.

## Architecture boundary

Preserve these ownership rules:

- completed compression studies remain the only inputs;
- `compareCompressionStudies` remains the compression-specific public entrypoint;
- shared group statistics remain under `mechanics.statistics` and `mechanics.workflow`;
- figures remain under `mechanics.plotting`;
- serialization and persistent figure export remain under `mechanics.io`;
- experiment-specific paths and group labels remain in the study driver;
- no Ecoflex-specific logic belongs in `src/+mechanics`.

Do not duplicate the comparison workflow in the driver and do not add model-specific $\mu_0$ formulas to plotting code.

## Merge and validation status

The comparison-visualization and reporting enhancement was merged through PR #53.

Merge commit:

```text
8f70dedad8d1420595f9d1c1a6be9f0992d8dd60
```

The former implementation branch was:

```text
feature/compression-study-comparison-visuals
```

The user regenerated and supplied the final Ecoflex 00-20 versus 00-50 comparison bundle after the final presentation/report refinements. The reviewed output contains:

- both stress-strain group means with pointwise bootstrap bands;
- the compression magnitude-difference panel;
- specimen-level scalar metric panels;
- tangent-modulus population comparison;
- annotated model-derived $\mu_0$ references;
- the maintained Markdown report with generic interpretation boundaries.

The reviewed final numerical summaries include approximately:

```text
Maximum strain mean
Ecoflex 00-20 = 0.38248
Ecoflex 00-50 = 0.37653
A - B = +0.00594
95% bootstrap interval = [-0.01324, +0.02243]

Maximum stress mean
Ecoflex 00-20 = 0.09964 MPa
Ecoflex 00-50 = 0.21519 MPa

Median tangent modulus mean
Ecoflex 00-20 = 0.19775 MPa
Ecoflex 00-50 = 0.47282 MPa

Model-derived initial shear modulus
Ecoflex 00-20 = 0.04268 MPa
Ecoflex 00-50 = 0.11266 MPa
00-50 / 00-20 ~= 2.64
```

The maximum-strain interval includes zero; the maintained report therefore does not claim a clear directional separation for that metric. The stress, tangent-modulus, and model-derived initial-shear results consistently indicate a stiffer response for Ecoflex 00-50 under the configured comparison.

The conversation does not contain an explicit final statement that `run_all_tests()` passed after the last presentation/report refinements. Do not retroactively claim a documented full-suite pass for PR #53 without a later user report. The final real-data bundle regeneration and review are documented.
