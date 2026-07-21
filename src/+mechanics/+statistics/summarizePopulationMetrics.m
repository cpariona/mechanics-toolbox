function summary = summarizePopulationMetrics(datasetSummary, config)
%SUMMARIZEPOPULATIONMETRICS Summarize scalar specimen-level outcomes.
arguments
    datasetSummary table
    config (1,1) struct = mechanics.config.populationAnalysisConfig()
end

requiredVariables = [ ...
    "Status", "MaximumStrain", "MaximumStress", ...
    "MedianTangentModulus"];

if ~all(ismember(requiredVariables, ...
        string(datasetSummary.Properties.VariableNames)))
    error("mechanics:statistics:InvalidDatasetSummary", ...
        "Dataset summary does not contain all required variables.");
end

processed = datasetSummary(datasetSummary.Status == "processed", :);

metricNames = [ ...
    "MaximumStrain"; ...
    "MaximumStress"; ...
    "MedianTangentModulus"];

metricCount = numel(metricNames);
sampleCount = zeros(metricCount, 1);
meanValue = nan(metricCount, 1);
standardDeviation = nan(metricCount, 1);
coefficientOfVariation = nan(metricCount, 1);
confidenceLower = nan(metricCount, 1);
confidenceUpper = nan(metricCount, 1);

for index = 1:metricCount
    values = processed.(metricNames(index));
    values = values(isfinite(values));

    sampleCount(index) = numel(values);

    if isempty(values)
        continue;
    end

    meanValue(index) = mean(values);
    standardDeviation(index) = std(values);

    if abs(meanValue(index)) > eps
        coefficientOfVariation(index) = ...
            standardDeviation(index) ./ abs(meanValue(index));
    end

    if config.bootstrap.enabled
        intervalConfig = config.bootstrap;
        intervalConfig.randomSeed = ...
            config.bootstrap.randomSeed + 1000 + index;

        interval = mechanics.statistics.bootstrapMeanConfidenceInterval( ...
            values, intervalConfig);

        confidenceLower(index) = interval.lower;
        confidenceUpper(index) = interval.upper;
    end
end

summary = table( ...
    metricNames, sampleCount, meanValue, standardDeviation, ...
    coefficientOfVariation, confidenceLower, confidenceUpper, ...
    'VariableNames', { ...
        'Metric', 'SampleCount', 'Mean', 'StandardDeviation', ...
        'CoefficientOfVariation', ...
        'ConfidenceLower', 'ConfidenceUpper'});
end
