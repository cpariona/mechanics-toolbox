# Study consensus constitutive model

The study consensus workflow selects one constitutive model using evidence from the same candidate model fitted across all specimens. It does not use majority vote over specimen-level winners and does not fit only the population central curve.

## Inputs

The workflow consumes the result of `mechanics.workflow.compareModelsAcrossSpecimens`:

```matlab
batchConfig = mechanics.config.batchModelComparisonConfig();
parameterBatch = mechanics.workflow.compareModelsAcrossSpecimens( ...
    specimens, modelNames, fitConfig, batchConfig);

consensusConfig = mechanics.config.studyConsensusModelConfig();
consensus = mechanics.workflow.selectStudyConsensusModel( ...
    parameterBatch, consensusConfig);
```

Every candidate model should therefore be evaluated on the same specimen set and with the same fitting context.

## Selection rules

For each model, the workflow reports:

```text
SuccessfulFitCount
SuccessfulFitFraction
EligibleFitCount
EligibleFitFraction
ParameterCount
MedianNormalizedRMSE
MedianBIC
Accepted
```

A model is accepted only when it meets both the minimum successful-fit fraction and the minimum eligible-fit fraction. Among accepted models, the lowest median BIC defines the leading evidence. Models within `bicTieTolerance` of that value are treated as practically tied, and the model with fewer parameters is preferred.

Default configuration:

```matlab
config.minimumSuccessfulFraction = 0.75;
config.minimumEligibleFraction = 0.75;
config.bicTieTolerance = 2.0;
```

## Result contract

```text
consensus.modelName
consensus.hasConsensusModel
consensus.selectedIndex
consensus.eligibleFraction
consensus.metricSummary
consensus.parameterTable
consensus.parameterSummary
consensus.reason
consensus.config
```

`parameterTable` contains the consensus-model fit parameters for every eligible specimen. `parameterSummary` reports the specimen count, median, and bootstrap confidence interval for each parameter.

## Export

```matlab
files = mechanics.io.exportStudyConsensusModel( ...
    consensus, "results/my-study/consensus-model");
```

The exporter writes:

```text
consensus_model_metrics.csv
consensus_model_parameters.csv
consensus_model_parameter_summary.csv
consensus_model.png
consensus_model.mat
```

The figure compares median BIC and eligible-fit fraction across candidate models. A fit to the population central curve may be added later as a complementary visualization, but it must not replace specimen-level consensus selection.
