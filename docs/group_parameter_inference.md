# Group inference for selected constitutive parameters

Phase 24 compares homologous selected-model parameters between groups.
Comparisons are performed separately for every `ModelName` and `Parameter`
combination. Parameters from different constitutive families are never pooled.

## Method

For each pair of groups, the workflow reports:

- group sample sizes and means;
- mean and median differences;
- bootstrap confidence interval for the mean difference;
- Hedges' g;
- Cliff's delta;
- two-sided permutation p-value;
- multiplicity-adjusted p-value;
- significance at the configured alpha level.

The default multiplicity correction is Benjamini-Hochberg false-discovery-rate
control. The implementation does not require the Statistics and Machine Learning
Toolbox.

## Usage

```matlab
config = mechanics.config.groupParameterInferenceConfig();
inference = mechanics.workflow.compareSelectedParametersBetweenGroups( ...
    population, config);
```

`population` is the output of
`mechanics.workflow.summarizeSelectedParameters`.

## Interpretation

Statistical significance does not establish biological relevance. Mean
differences, confidence intervals, effect sizes, sample sizes, fit reliability,
and the constitutive meaning of each parameter should be reviewed together.
