# Experimental group comparison

Phase 10 compares processed replicate populations assigned to experimental groups.

## Assignment

```matlab
assignments = table(specimenIds, groupLabels, ...
    'VariableNames', {'SpecimenId','Group'});
groupedAnalysis = mechanics.workflow.assignSpecimenGroups(analysis, assignments);
```

## Comparison

```matlab
config = mechanics.config.groupComparisonConfig();
comparison = mechanics.workflow.analyzeGroupComparison( ...
    groupedAnalysis, ["control","treated"], config);
```

Each group is first analyzed through the Phase 9 population workflow. For two
groups, Phase 10 reports mean stress curves, their difference `A-B`, bootstrap
confidence intervals, and comparisons of maximum strain, maximum stress, and
median tangent modulus.

More than two groups are supported descriptively; direct pairwise output is
created only when exactly two groups are requested.
