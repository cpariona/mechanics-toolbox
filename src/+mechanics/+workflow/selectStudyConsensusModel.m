function consensus = selectStudyConsensusModel(batch, config)
%SELECTSTUDYCONSENSUSMODEL Select one constitutive model across specimens.
arguments
    batch (1,1) struct
    config (1,1) struct = mechanics.config.studyConsensusModelConfig()
end

required = {'modelNames','specimenCount','comparisons'};
if ~all(isfield(batch, required))
    error('mechanics:workflow:InvalidConsensusBatch', ...
        'Batch result is missing modelNames, specimenCount, or comparisons.');
end

modelNames = string(batch.modelNames(:));
specimenCount = double(batch.specimenCount);
modelCount = numel(modelNames);

successfulCount = zeros(modelCount,1);
eligibleCount = zeros(modelCount,1);
medianBIC = nan(modelCount,1);
medianNormalizedRMSE = nan(modelCount,1);
parameterCount = nan(modelCount,1);

bicValues = cell(modelCount,1);
normalizedRmseValues = cell(modelCount,1);

for specimenIndex = 1:numel(batch.comparisons)
    comparison = batch.comparisons{specimenIndex};
    if isempty(comparison) || ~isfield(comparison,'summary')
        continue;
    end
    summary = comparison.summary;
    for modelIndex = 1:modelCount
        row = find(string(summary.ModelName) == modelNames(modelIndex), 1);
        if isempty(row)
            continue;
        end
        if summary.Success(row)
            successfulCount(modelIndex) = successfulCount(modelIndex) + 1;
        end
        if summary.Eligible(row)
            eligibleCount(modelIndex) = eligibleCount(modelIndex) + 1;
        end
        if isfinite(summary.BIC(row))
            bicValues{modelIndex}(end+1,1) = summary.BIC(row); %#ok<AGROW>
        end
        if isfinite(summary.NormalizedRMSE(row))
            normalizedRmseValues{modelIndex}(end+1,1) = ...
                summary.NormalizedRMSE(row); %#ok<AGROW>
        end
        if isfinite(summary.ParameterCount(row))
            parameterCount(modelIndex) = summary.ParameterCount(row);
        end
    end
end

for modelIndex = 1:modelCount
    if ~isempty(bicValues{modelIndex})
        medianBIC(modelIndex) = median(bicValues{modelIndex});
    end
    if ~isempty(normalizedRmseValues{modelIndex})
        medianNormalizedRMSE(modelIndex) = ...
            median(normalizedRmseValues{modelIndex});
    end
end

successfulFraction = successfulCount ./ max(specimenCount,1);
eligibleFraction = eligibleCount ./ max(specimenCount,1);
accepted = successfulFraction >= config.minimumSuccessfulFraction & ...
    eligibleFraction >= config.minimumEligibleFraction & isfinite(medianBIC);

deltaBIC = nan(modelCount,1);
if any(accepted)
    bestAcceptedBIC = min(medianBIC(accepted));
    deltaBIC(accepted) = medianBIC(accepted) - bestAcceptedBIC;
end

selectedIndex = NaN;
reason = "No model satisfied the consensus eligibility thresholds.";
if any(accepted)
    acceptedIndices = find(accepted);
    bestBIC = min(medianBIC(accepted));
    tied = acceptedIndices(medianBIC(accepted) <= ...
        bestBIC + config.bicTieTolerance);

    if numel(tied) == 1
        selectedIndex = tied;
        reason = "Selected by lowest median BIC.";
    else
        tiedParameterCount = parameterCount(tied);
        minimumParameterCount = min(tiedParameterCount);
        parsimonious = tied(tiedParameterCount == minimumParameterCount);
        if numel(parsimonious) == 1
            selectedIndex = parsimonious;
            reason = ...
                "Selected by parsimony among models within the median-BIC tie tolerance.";
        else
            [~, localIndex] = min(medianBIC(parsimonious));
            selectedIndex = parsimonious(localIndex);
            reason = ...
                "Selected by lowest median BIC after applying tie tolerance and parsimony.";
        end
    end
end

metricSummary = table(modelNames, successfulCount, successfulFraction, ...
    eligibleCount, eligibleFraction, parameterCount, medianNormalizedRMSE, ...
    medianBIC, deltaBIC, accepted, ...
    'VariableNames', {'ModelName','SuccessfulFitCount', ...
    'SuccessfulFitFraction','EligibleFitCount','EligibleFitFraction', ...
    'ParameterCount','MedianNormalizedRMSE','MedianBIC','DeltaBIC','Accepted'});

parameterTable = localParameterTable(batch, modelNames, selectedIndex, config);
parameterSummary = localParameterSummary(parameterTable, config);

consensus.modelName = "";
if isfinite(selectedIndex)
    consensus.modelName = modelNames(selectedIndex);
end
consensus.hasConsensusModel = isfinite(selectedIndex);
consensus.selectedIndex = selectedIndex;
consensus.eligibleFraction = NaN;
if isfinite(selectedIndex)
    consensus.eligibleFraction = eligibleFraction(selectedIndex);
end
consensus.metricSummary = metricSummary;
consensus.parameterTable = parameterTable;
consensus.parameterSummary = parameterSummary;
consensus.reason = reason;
consensus.config = config;
consensus.createdAt = datetime('now');
end

function output = localParameterTable(batch, modelNames, selectedIndex, config)
output = table(strings(0,1),strings(0,1),strings(0,1),zeros(0,1), ...
    'VariableNames', {'SpecimenId','ModelName','Parameter','Value'});
if ~isfinite(selectedIndex)
    return;
end
selectedModel = modelNames(selectedIndex);
for specimenIndex = 1:numel(batch.comparisons)
    comparison = batch.comparisons{specimenIndex};
    if isempty(comparison) || ~isfield(comparison,'summary')
        continue;
    end
    summary = comparison.summary;
    row = find(string(summary.ModelName) == selectedModel, 1);
    if isempty(row) || ~summary.Success(row) || ~summary.Eligible(row)
        continue;
    end
    analysis = comparison.analyses{row};
    fitResult = analysis.fitResult;
    values = fitResult.parameters(:);
    if config.requireFiniteParameters && any(~isfinite(values))
        continue;
    end
    definition = mechanics.models.modelRegistry(selectedModel);
    names = string(definition.parameterNames(:));
    specimenId = string(batch.specimenSummary.SpecimenId(specimenIndex));
    count = numel(values);
    rows = table(repmat(specimenId,count,1), repmat(selectedModel,count,1), ...
        names, values, 'VariableNames', output.Properties.VariableNames);
    output = [output; rows]; %#ok<AGROW>
end
end

function output = localParameterSummary(input, config)
output = table(strings(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
    'VariableNames', {'Parameter','SpecimenCount','Median', ...
    'ConfidenceLower','ConfidenceUpper'});
if isempty(input)
    return;
end
parameterNames = unique(input.Parameter,'stable');
alpha = (1 - config.bootstrap.confidenceLevel) / 2;
for index = 1:numel(parameterNames)
    values = input.Value(input.Parameter == parameterNames(index));
    values = values(isfinite(values));
    lower = NaN;
    upper = NaN;
    if config.bootstrap.enabled && ~isempty(values)
        previousState = rng;
        cleanup = onCleanup(@() rng(previousState)); %#ok<NASGU>
        rng(config.bootstrap.randomSeed + index - 1);
        sampleCount = numel(values);
        bootstrapMedian = zeros(config.bootstrap.iterations,1);
        for iteration = 1:config.bootstrap.iterations
            indices = randi(sampleCount,sampleCount,1);
            bootstrapMedian(iteration) = median(values(indices));
        end
        limits = prctile(bootstrapMedian,100 .* [alpha,1-alpha]);
        lower = limits(1);
        upper = limits(2);
    end
    output(end+1,:) = {parameterNames(index),numel(values),median(values), ...
        lower,upper}; %#ok<AGROW>
end
end
