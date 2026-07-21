function inference = compareSelectedParametersBetweenGroups(population, config)
%COMPARESELECTEDPARAMETERSBETWEENGROUPS Compare homologous parameters by group.
arguments
    population (1,1) struct
    config (1,1) struct = mechanics.config.groupParameterInferenceConfig()
end

if ~isfield(population, 'parameterTable')
    error('mechanics:workflow:InvalidParameterPopulation', ...
        'population must contain parameterTable.');
end
input = population.parameterTable;
required = {'Group','ModelName','Parameter','Value'};
if ~all(ismember(required, input.Properties.VariableNames))
    error('mechanics:workflow:InvalidParameterPopulationTable', ...
        'parameterTable is missing required variables.');
end

rng(config.randomSeed, 'twister');
modelName = strings(0,1);
parameterName = strings(0,1);
group1 = strings(0,1);
group2 = strings(0,1);
count1 = zeros(0,1);
count2 = zeros(0,1);
mean1 = zeros(0,1);
mean2 = zeros(0,1);
meanDifference = zeros(0,1);
medianDifference = zeros(0,1);
ciLower = zeros(0,1);
ciUpper = zeros(0,1);
hedgesG = zeros(0,1);
cliffsDelta = zeros(0,1);
permutationPValue = zeros(0,1);
errorIdentifier = strings(0,1);
errorMessage = strings(0,1);

keys = unique(input(:, {'ModelName','Parameter'}), 'rows', 'stable');
for keyIndex = 1:height(keys)
    mask = input.ModelName == keys.ModelName(keyIndex) & ...
        input.Parameter == keys.Parameter(keyIndex) & strlength(input.Group) > 0;
    subset = input(mask,:);
    groups = unique(subset.Group, 'stable');
    for firstIndex = 1:max(0, numel(groups)-1)
        for secondIndex = firstIndex+1:numel(groups)
            try
                x = subset.Value(subset.Group == groups(firstIndex));
                y = subset.Value(subset.Group == groups(secondIndex));
                if config.requireFiniteValues
                    x = x(isfinite(x));
                    y = y(isfinite(y));
                end
                if numel(x) < config.minimumSpecimensPerGroup || ...
                        numel(y) < config.minimumSpecimensPerGroup
                    error('mechanics:workflow:InsufficientGroupParameterData', ...
                        'Each group requires at least %d finite observations.', ...
                        config.minimumSpecimensPerGroup);
                end

                difference = mean(x) - mean(y);
                bootstrapDifference = localBootstrapMeanDifference( ...
                    x, y, config.bootstrapCount);
                tail = (1 - config.alpha) / 2;
                lower = localPercentile(bootstrapDifference, tail);
                upper = localPercentile(bootstrapDifference, 1-tail);
                pValue = localPermutationPValue(x, y, config.permutationCount);

                modelName(end+1,1) = keys.ModelName(keyIndex); %#ok<AGROW>
                parameterName(end+1,1) = keys.Parameter(keyIndex); %#ok<AGROW>
                group1(end+1,1) = groups(firstIndex); %#ok<AGROW>
                group2(end+1,1) = groups(secondIndex); %#ok<AGROW>
                count1(end+1,1) = numel(x); %#ok<AGROW>
                count2(end+1,1) = numel(y); %#ok<AGROW>
                mean1(end+1,1) = mean(x); %#ok<AGROW>
                mean2(end+1,1) = mean(y); %#ok<AGROW>
                meanDifference(end+1,1) = difference; %#ok<AGROW>
                medianDifference(end+1,1) = median(x) - median(y); %#ok<AGROW>
                ciLower(end+1,1) = lower; %#ok<AGROW>
                ciUpper(end+1,1) = upper; %#ok<AGROW>
                hedgesG(end+1,1) = localHedgesG(x, y); %#ok<AGROW>
                cliffsDelta(end+1,1) = localCliffsDelta(x, y); %#ok<AGROW>
                permutationPValue(end+1,1) = pValue; %#ok<AGROW>
                errorIdentifier(end+1,1) = ""; %#ok<AGROW>
                errorMessage(end+1,1) = ""; %#ok<AGROW>
            catch ME
                modelName(end+1,1) = keys.ModelName(keyIndex); %#ok<AGROW>
                parameterName(end+1,1) = keys.Parameter(keyIndex); %#ok<AGROW>
                group1(end+1,1) = groups(firstIndex); %#ok<AGROW>
                group2(end+1,1) = groups(secondIndex); %#ok<AGROW>
                count1(end+1,1) = nnz(subset.Group == groups(firstIndex)); %#ok<AGROW>
                count2(end+1,1) = nnz(subset.Group == groups(secondIndex)); %#ok<AGROW>
                mean1(end+1,1) = NaN; %#ok<AGROW>
                mean2(end+1,1) = NaN; %#ok<AGROW>
                meanDifference(end+1,1) = NaN; %#ok<AGROW>
                medianDifference(end+1,1) = NaN; %#ok<AGROW>
                ciLower(end+1,1) = NaN; %#ok<AGROW>
                ciUpper(end+1,1) = NaN; %#ok<AGROW>
                hedgesG(end+1,1) = NaN; %#ok<AGROW>
                cliffsDelta(end+1,1) = NaN; %#ok<AGROW>
                permutationPValue(end+1,1) = NaN; %#ok<AGROW>
                errorIdentifier(end+1,1) = string(ME.identifier); %#ok<AGROW>
                errorMessage(end+1,1) = string(ME.message); %#ok<AGROW>
                if ~config.continueOnComparisonError
                    rethrow(ME);
                end
            end
        end
    end
end

adjustedPValue = localAdjustPValues(permutationPValue, ...
    config.multipleComparisonMethod);
significant = adjustedPValue < config.alpha;
comparisonTable = table(modelName, parameterName, group1, group2, ...
    count1, count2, mean1, mean2, meanDifference, medianDifference, ...
    ciLower, ciUpper, hedgesG, cliffsDelta, permutationPValue, ...
    adjustedPValue, significant, errorIdentifier, errorMessage, ...
    'VariableNames', {'ModelName','Parameter','Group1','Group2', ...
    'Group1Count','Group2Count','Group1Mean','Group2Mean', ...
    'MeanDifference','MedianDifference','ConfidenceIntervalLower', ...
    'ConfidenceIntervalUpper','HedgesG','CliffsDelta', ...
    'PermutationPValue','AdjustedPValue','Significant', ...
    'ErrorIdentifier','ErrorMessage'});

inference.comparisonTable = comparisonTable;
inference.comparisonCount = height(comparisonTable);
inference.successfulComparisonCount = nnz(isfinite(permutationPValue));
inference.significantComparisonCount = nnz(significant);
inference.config = config;
inference.createdAt = datetime('now');
end

function samples = localBootstrapMeanDifference(x, y, count)
samples = zeros(count,1);
for index = 1:count
    xSample = x(randi(numel(x), numel(x), 1));
    ySample = y(randi(numel(y), numel(y), 1));
    samples(index) = mean(xSample) - mean(ySample);
end
end

function pValue = localPermutationPValue(x, y, count)
observed = abs(mean(x) - mean(y));
combined = [x(:); y(:)];
firstCount = numel(x);
totalCombinationCount = nchoosek(numel(combined), firstCount);

if isfinite(totalCombinationCount) && totalCombinationCount <= count
    assignments = nchoosek(1:numel(combined), firstCount);
    exceedance = 0;
    allIndices = 1:numel(combined);
    for index = 1:size(assignments,1)
        firstMask = false(numel(combined),1);
        firstMask(assignments(index,:)) = true;
        first = combined(firstMask);
        second = combined(allIndices(~firstMask));
        exceedance = exceedance + ...
            (abs(mean(first)-mean(second)) >= observed);
    end
    pValue = exceedance / totalCombinationCount;
    return;
end

exceedance = 0;
for index = 1:count
    order = randperm(numel(combined));
    first = combined(order(1:firstCount));
    second = combined(order(firstCount+1:end));
    exceedance = exceedance + (abs(mean(first)-mean(second)) >= observed);
end
pValue = (exceedance + 1) / (count + 1);
end

function value = localHedgesG(x, y)
n1 = numel(x);
n2 = numel(y);
pooledVariance = ((n1-1)*var(x,0) + (n2-1)*var(y,0)) / (n1+n2-2);
if pooledVariance <= 0
    value = 0;
    return;
end
cohensD = (mean(x)-mean(y)) / sqrt(pooledVariance);
correction = 1 - 3 / (4*(n1+n2)-9);
value = correction * cohensD;
end

function value = localCliffsDelta(x, y)
difference = x(:) - y(:)';
value = (nnz(difference > 0) - nnz(difference < 0)) / numel(difference);
end

function value = localPercentile(samples, probability)
sorted = sort(samples(:));
position = 1 + (numel(sorted)-1)*probability;
lowerIndex = floor(position);
upperIndex = ceil(position);
if lowerIndex == upperIndex
    value = sorted(lowerIndex);
else
    fraction = position-lowerIndex;
    value = sorted(lowerIndex)*(1-fraction) + sorted(upperIndex)*fraction;
end
end

function adjusted = localAdjustPValues(pValues, method)
adjusted = nan(size(pValues));
valid = find(isfinite(pValues));
if isempty(valid)
    return;
end
switch lower(string(method))
    case "none"
        adjusted(valid) = pValues(valid);
    case "benjamini-hochberg"
        [ordered, order] = sort(pValues(valid));
        count = numel(ordered);
        corrected = ordered .* count ./ (1:count)';
        corrected = flipud(cummin(flipud(corrected)));
        corrected = min(corrected, 1);
        restored = zeros(count,1);
        restored(order) = corrected;
        adjusted(valid) = restored;
    otherwise
        error('mechanics:workflow:UnknownMultiplicityMethod', ...
            'Unknown multiple-comparison method: %s.', string(method));
end
end