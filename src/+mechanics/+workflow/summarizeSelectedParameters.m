function population = summarizeSelectedParameters(batch, config)
%SUMMARIZESELECTEDPARAMETERS Summarize selected-model parameters across specimens.
arguments
    batch (1,1) struct
    config (1,1) struct = mechanics.config.selectedParameterPopulationConfig()
end

required = {'specimenSummary','comparisons'};
if ~all(isfield(batch, required))
    error('mechanics:workflow:InvalidSelectedParameterBatch', ...
        'Batch result is missing specimenSummary or comparisons.');
end

summary = batch.specimenSummary;
rowSpecimen = strings(0,1);
rowGroup = strings(0,1);
rowModel = strings(0,1);
rowParameter = strings(0,1);
rowValue = zeros(0,1);
rowLower = nan(0,1);
rowMedian = nan(0,1);
rowUpper = nan(0,1);
errorSpecimen = strings(0,1);
errorIdentifier = strings(0,1);
errorMessage = strings(0,1);

for index = 1:height(summary)
    if ~summary.Success(index) || ~summary.HasSelectedModel(index)
        continue;
    end
    try
        comparison = batch.comparisons{index};
        selectedIndex = comparison.selectedIndex;
        analysis = comparison.analyses{selectedIndex};
        fitResult = analysis.fitResult;
        model = mechanics.models.modelRegistry(string(fitResult.modelName));
        names = string(model.parameterNames(:));
        values = fitResult.parameters(:);
        if numel(names) ~= numel(values)
            error('mechanics:workflow:SelectedParameterSizeMismatch', ...
                'Parameter names and fitted values have different lengths.');
        end
        if config.requireFiniteParameters && any(~isfinite(values))
            error('mechanics:workflow:NonfiniteSelectedParameter', ...
                'Selected fit contains nonfinite parameter values.');
        end

        lower = nan(size(values));
        medianValue = nan(size(values));
        upper = nan(size(values));
        if isfield(analysis, 'uncertainty') && ...
                isfield(analysis.uncertainty, 'parameterLower')
            lower = analysis.uncertainty.parameterLower(:);
            medianValue = analysis.uncertainty.parameterMedian(:);
            upper = analysis.uncertainty.parameterUpper(:);
        end

        count = numel(values);
        rowSpecimen(end+1:end+count,1) = summary.SpecimenId(index); %#ok<AGROW>
        rowGroup(end+1:end+count,1) = summary.Group(index); %#ok<AGROW>
        rowModel(end+1:end+count,1) = string(fitResult.modelName); %#ok<AGROW>
        rowParameter(end+1:end+count,1) = names; %#ok<AGROW>
        rowValue(end+1:end+count,1) = values; %#ok<AGROW>
        rowLower(end+1:end+count,1) = lower; %#ok<AGROW>
        rowMedian(end+1:end+count,1) = medianValue; %#ok<AGROW>
        rowUpper(end+1:end+count,1) = upper; %#ok<AGROW>
    catch ME
        errorSpecimen(end+1,1) = summary.SpecimenId(index); %#ok<AGROW>
        errorIdentifier(end+1,1) = string(ME.identifier); %#ok<AGROW>
        errorMessage(end+1,1) = string(ME.message); %#ok<AGROW>
        if ~config.continueOnExtractionError
            rethrow(ME);
        end
    end
end

parameterTable = table(rowSpecimen, rowGroup, rowModel, rowParameter, ...
    rowValue, rowLower, rowMedian, rowUpper, ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter', ...
    'Value','BootstrapLower','BootstrapMedian','BootstrapUpper'});
errorTable = table(errorSpecimen, errorIdentifier, errorMessage, ...
    'VariableNames', {'SpecimenId','ErrorIdentifier','ErrorMessage'});

overallSummary = localSummarize(parameterTable, false, config);
if config.includeGroupSummary
    groupSummary = localSummarize(parameterTable, true, config);
else
    groupSummary = localEmptySummary(true);
end

population.parameterTable = parameterTable;
population.overallSummary = overallSummary;
population.groupSummary = groupSummary;
population.extractionErrors = errorTable;
population.parameterObservationCount = height(parameterTable);
population.specimenCount = numel(unique(parameterTable.SpecimenId));
population.config = config;
population.createdAt = datetime('now');
end

function output = localSummarize(input, byGroup, config)
if isempty(input)
    output = localEmptySummary(byGroup);
    return;
end
if byGroup
    groups = findgroups(input.Group, input.ModelName, input.Parameter);
    [groupName, modelName, parameterName] = splitapply( ...
        @(g,m,p) deal(g(1),m(1),p(1)), ...
        input.Group, input.ModelName, input.Parameter, groups);
else
    groups = findgroups(input.ModelName, input.Parameter);
    [modelName, parameterName] = splitapply( ...
        @(m,p) deal(m(1),p(1)), input.ModelName, input.Parameter, groups);
    groupName = strings(numel(modelName),1);
end
count = splitapply(@numel, input.Value, groups);
meanValue = splitapply(@mean, input.Value, groups);
standardDeviation = splitapply(@(x) std(x,0), input.Value, groups);
medianValue = splitapply(@median, input.Value, groups);
minimumValue = splitapply(@min, input.Value, groups);
maximumValue = splitapply(@max, input.Value, groups);
coefficientOfVariation = standardDeviation ./ max(abs(meanValue), sqrt(eps));
validSummary = count >= config.minimumSpecimensPerSummary;

if byGroup
    output = table(groupName, modelName, parameterName, count, meanValue, ...
        standardDeviation, medianValue, minimumValue, maximumValue, ...
        coefficientOfVariation, validSummary, ...
        'VariableNames', {'Group','ModelName','Parameter','SpecimenCount', ...
        'Mean','StandardDeviation','Median','Minimum','Maximum', ...
        'CoefficientOfVariation','MeetsMinimumCount'});
else
    output = table(modelName, parameterName, count, meanValue, ...
        standardDeviation, medianValue, minimumValue, maximumValue, ...
        coefficientOfVariation, validSummary, ...
        'VariableNames', {'ModelName','Parameter','SpecimenCount', ...
        'Mean','StandardDeviation','Median','Minimum','Maximum', ...
        'CoefficientOfVariation','MeetsMinimumCount'});
end
end

function output = localEmptySummary(byGroup)
if byGroup
    output = table(strings(0,1),strings(0,1),strings(0,1),zeros(0,1), ...
        zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
        zeros(0,1),false(0,1), ...
        'VariableNames', {'Group','ModelName','Parameter','SpecimenCount', ...
        'Mean','StandardDeviation','Median','Minimum','Maximum', ...
        'CoefficientOfVariation','MeetsMinimumCount'});
else
    output = table(strings(0,1),strings(0,1),zeros(0,1),zeros(0,1), ...
        zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),false(0,1), ...
        'VariableNames', {'ModelName','Parameter','SpecimenCount', ...
        'Mean','StandardDeviation','Median','Minimum','Maximum', ...
        'CoefficientOfVariation','MeetsMinimumCount'});
end
end
