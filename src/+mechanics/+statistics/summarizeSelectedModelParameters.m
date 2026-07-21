function result = summarizeSelectedModelParameters(records, config)
%SUMMARIZESELECTEDMODELPARAMETERS Aggregate selected model parameters.
arguments
    records struct
    config (1,1) struct = mechanics.config.populationAnalysisConfig()
end

specimenId = strings(0, 1);
modelName = strings(0, 1);
parameterName = strings(0, 1);
parameterValue = zeros(0, 1);

for recordIndex = 1:numel(records)
    record = records(recordIndex);

    if record.status ~= "processed" || ...
            ~isfield(record.specimen, "modelSelection")
        continue;
    end

    study = record.specimen.modelSelection;
    if ~study.selection.hasEligibleModel
        continue;
    end

    selectedModel = study.selection.bestModel;
    modelRecords = study.records( ...
        [study.records.modelName] == selectedModel & ...
        [study.records.succeeded]);

    if isempty(modelRecords)
        continue;
    end

    fractions = [modelRecords.windowFraction];
    [~, fullIndex] = max(fractions);
    fitResult = modelRecords(fullIndex).fitResult;

    names = string(fitResult.parameterNames(:));
    values = fitResult.parameters(:);

    rowCount = numel(names);
    specimenId = [specimenId; ...
        repmat(string(record.specimenId), rowCount, 1)]; %#ok<AGROW>
    modelName = [modelName; ...
        repmat(string(selectedModel), rowCount, 1)]; %#ok<AGROW>
    parameterName = [parameterName; names]; %#ok<AGROW>
    parameterValue = [parameterValue; values]; %#ok<AGROW>
end

longTable = table( ...
    specimenId, modelName, parameterName, parameterValue, ...
    'VariableNames', { ...
        'SpecimenId', 'Model', 'Parameter', 'Value'});

if isempty(longTable)
    result.values = longTable;
    result.summary = table();
    return;
end

keys = unique(longTable(:, {'Model', 'Parameter'}), "rows", "stable");
groupCount = height(keys);

sampleCount = zeros(groupCount, 1);
meanValue = nan(groupCount, 1);
standardDeviation = nan(groupCount, 1);
coefficientOfVariation = nan(groupCount, 1);
confidenceLower = nan(groupCount, 1);
confidenceUpper = nan(groupCount, 1);

for groupIndex = 1:groupCount
    mask = longTable.Model == keys.Model(groupIndex) & ...
        longTable.Parameter == keys.Parameter(groupIndex);
    values = longTable.Value(mask);
    values = values(isfinite(values));

    sampleCount(groupIndex) = numel(values);

    if isempty(values)
        continue;
    end

    meanValue(groupIndex) = mean(values);
    standardDeviation(groupIndex) = std(values);

    if abs(meanValue(groupIndex)) > eps
        coefficientOfVariation(groupIndex) = ...
            standardDeviation(groupIndex) ./ abs(meanValue(groupIndex));
    end

    if config.bootstrap.enabled
        intervalConfig = config.bootstrap;
        intervalConfig.randomSeed = ...
            config.bootstrap.randomSeed + 2000 + groupIndex;

        interval = mechanics.statistics.bootstrapMeanConfidenceInterval( ...
            values, intervalConfig);

        confidenceLower(groupIndex) = interval.lower;
        confidenceUpper(groupIndex) = interval.upper;
    end
end

summary = table( ...
    keys.Model, keys.Parameter, ...
    sampleCount, meanValue, standardDeviation, ...
    coefficientOfVariation, confidenceLower, confidenceUpper, ...
    'VariableNames', { ...
        'Model', 'Parameter', 'SampleCount', 'Mean', ...
        'StandardDeviation', 'CoefficientOfVariation', ...
        'ConfidenceLower', 'ConfidenceUpper'});

result.values = longTable;
result.summary = summary;
end
