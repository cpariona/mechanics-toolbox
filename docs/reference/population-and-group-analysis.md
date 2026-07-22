# Population and group analysis

## Replicate population analysis

```matlab
config = mechanics.config.populationAnalysisConfig();
population = mechanics.workflow.analyzeSpecimenPopulation( ...
    analysis, config);
```

Successfully processed specimens are interpolated onto a common strain range. The workflow reports the mean response, standard deviation, standard error, bootstrap confidence intervals, scalar specimen summaries, and selected-model parameter summaries.

Bootstrap resampling is performed over specimens rather than individual points within one specimen.

The main outputs are:

```text
population.curves
population.metrics
population.modelParameters
population.specimenIds
population.specimenCount
```

## Experimental group comparison

Assign specimens to groups:

```matlab
assignments = table(specimenIds, groupLabels, ...
    'VariableNames', {'SpecimenId','Group'});
grouped = mechanics.workflow.assignSpecimenGroups(analysis, assignments);
```

Then compare groups:

```matlab
config = mechanics.config.groupComparisonConfig();
comparison = mechanics.workflow.analyzeGroupComparison( ...
    grouped, ["control","treated"], config);
```

Each group is summarized independently. For exactly two groups, the workflow reports mean stress curves, their difference, bootstrap confidence intervals, and comparisons of maximum strain, maximum stress, and median tangent modulus. More than two groups are supported descriptively.

These population-level comparisons are distinct from inference on selected constitutive parameters, which is documented in the constitutive-analysis workflow.
