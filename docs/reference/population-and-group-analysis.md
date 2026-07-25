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

## Comparing completed tensile studies

Use `compareTensileStudies` when each material or experimental condition has already been processed independently with `runTensileStudy`:

```matlab
study0020 = mechanics.workflow.runTensileStudy( ...
    ecoflex0020Workbook, tensileConfig0020);
study0050 = mechanics.workflow.runTensileStudy( ...
    ecoflex0050Workbook, tensileConfig0050);

config = mechanics.config.tensileStudyComparisonConfig();
comparison = mechanics.workflow.compareTensileStudies( ...
    [study0020, study0050], ...
    ["ECOFLEX 00-20", "ECOFLEX 00-50"], ...
    config);
```

This workflow does not re-import files or rerun specimen processing. It validates compatible strain measures, stress measures, and processed units; combines copies of the specimen-level analysis; assigns one explicit group label per study; and delegates population and group statistics to `analyzeGroupComparison`.

Specimen identifiers may repeat across workbooks. The comparison creates internal namespaced identifiers such as `study-1::specimen-1` while preserving the original identifiers in the combined analysis metadata. The input study structs are not modified.

The main result fields are:

```text
comparison.groupLabels
comparison.studySummaries
comparison.compatibility
comparison.groupComparison
comparison.config
comparison.createdAt
```

The first maintained scope covers population stress-strain curves and scalar mechanical metrics. Constitutive-parameter and consensus-model comparison remain separate downstream extensions.

These population-level comparisons are distinct from inference on selected constitutive parameters, which is documented in the constitutive-analysis workflow.
