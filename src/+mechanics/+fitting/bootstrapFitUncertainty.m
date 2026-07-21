function uncertainty = bootstrapFitUncertainty(fitResult, config)
%BOOTSTRAPFITUNCERTAINTY Estimate parameter and prediction uncertainty.
arguments
    fitResult (1,1) struct
    config (1,1) struct = mechanics.config.fitUncertaintyConfig()
end

required = ["modelName", "parameters", "deformation", ...
    "measuredStress", "predictedStress", "residuals", ...
    "context", "config", "parameterNames"];
if ~all(isfield(fitResult, required))
    error("mechanics:fitting:InvalidFitResult", ...
        "fitResult is missing fields required for bootstrap uncertainty.");
end

if config.method ~= "residual"
    error("mechanics:fitting:UnknownBootstrapMethod", ...
        "Unknown bootstrap method: %s", config.method);
end

sampleCount = round(config.sampleCount);
if ~isscalar(sampleCount) || sampleCount < 2
    error("mechanics:fitting:InvalidBootstrapSampleCount", ...
        "sampleCount must be an integer greater than one.");
end

confidenceLevel = config.confidenceLevel;
if ~isscalar(confidenceLevel) || ~isfinite(confidenceLevel) || ...
        confidenceLevel <= 0 || confidenceLevel >= 1
    error("mechanics:fitting:InvalidConfidenceLevel", ...
        "confidenceLevel must lie in (0, 1).");
end

x = fitResult.deformation(:);
yhat = fitResult.predictedStress(:);
residuals = fitResult.residuals(:);
residuals = residuals - mean(residuals);

if isempty(config.predictionDeformation)
    predictionX = x;
else
    predictionX = config.predictionDeformation(:);
end

parameterCount = numel(fitResult.parameters);
predictionCount = numel(predictionX);
parameterSamples = nan(sampleCount, parameterCount);
predictionSamples = nan(predictionCount, sampleCount);
successMask = false(sampleCount, 1);

if config.storeBootstrapFits
    bootstrapFits = cell(sampleCount, 1);
else
    bootstrapFits = {};
end

refitConfig = fitResult.config;
refitConfig.initialGuess = fitResult.parameters;
refitConfig.numberOfStarts = config.refitNumberOfStarts;
refitConfig.weights = [];

rng(config.randomSeed, "twister");
observationCount = numel(residuals);

for index = 1:sampleCount
    sampledResiduals = residuals(randi(observationCount, observationCount, 1));
    bootstrapStress = yhat + sampledResiduals;
    refitConfig.randomSeed = config.randomSeed + index;

    try
        bootstrapFit = mechanics.fitting.fitModel( ...
            fitResult.modelName, x, bootstrapStress, ...
            fitResult.context, refitConfig);

        prediction = mechanics.models.evaluateModel( ...
            fitResult.modelName, predictionX, ...
            bootstrapFit.parameters, fitResult.context);

        parameterSamples(index, :) = bootstrapFit.parameters;
        predictionSamples(:, index) = prediction(:);
        successMask(index) = true;

        if config.storeBootstrapFits
            bootstrapFits{index} = bootstrapFit;
        end
    catch
        % Failed refits are retained as NaN and reported in success metrics.
    end
end

successfulCount = nnz(successMask);
successfulFraction = successfulCount ./ sampleCount;
if successfulFraction < config.minimumSuccessfulFraction
    error("mechanics:fitting:InsufficientBootstrapSuccess", ...
        ["Only %.1f%% of bootstrap refits succeeded; " ...
        "the configured minimum is %.1f%%."], ...
        100 * successfulFraction, ...
        100 * config.minimumSuccessfulFraction);
end

alpha = (1 - confidenceLevel) ./ 2;
lowerProbability = alpha;
upperProbability = 1 - alpha;

validParameters = parameterSamples(successMask, :);
validPredictions = predictionSamples(:, successMask);

parameterLower = localPercentile(validParameters, lowerProbability, 1);
parameterMedian = localPercentile(validParameters, 0.5, 1);
parameterUpper = localPercentile(validParameters, upperProbability, 1);

predictionLower = localPercentile(validPredictions, lowerProbability, 2);
predictionMedian = localPercentile(validPredictions, 0.5, 2);
predictionUpper = localPercentile(validPredictions, upperProbability, 2);

uncertainty.modelName = fitResult.modelName;
uncertainty.parameterNames = fitResult.parameterNames;
uncertainty.baseParameters = fitResult.parameters;
uncertainty.parameterSamples = parameterSamples;
uncertainty.parameterLower = parameterLower;
uncertainty.parameterMedian = parameterMedian;
uncertainty.parameterUpper = parameterUpper;
uncertainty.predictionDeformation = predictionX;
uncertainty.predictionSamples = predictionSamples;
uncertainty.predictionLower = predictionLower;
uncertainty.predictionMedian = predictionMedian;
uncertainty.predictionUpper = predictionUpper;
uncertainty.successMask = successMask;
uncertainty.successfulCount = successfulCount;
uncertainty.successfulFraction = successfulFraction;
uncertainty.confidenceLevel = confidenceLevel;
uncertainty.config = config;
uncertainty.bootstrapFits = bootstrapFits;
end

function values = localPercentile(data, probability, dimension)
if dimension == 1
    values = nan(1, size(data, 2));
    for column = 1:size(data, 2)
        values(column) = localVectorPercentile(data(:, column), probability);
    end
else
    values = nan(size(data, 1), 1);
    for row = 1:size(data, 1)
        values(row) = localVectorPercentile(data(row, :)', probability);
    end
end
end

function value = localVectorPercentile(values, probability)
values = sort(values(isfinite(values)));
count = numel(values);
if count == 0
    value = NaN;
    return;
end
if count == 1
    value = values(1);
    return;
end
position = 1 + (count - 1) * probability;
lowerIndex = floor(position);
upperIndex = ceil(position);
weight = position - lowerIndex;
value = (1 - weight) * values(lowerIndex) + weight * values(upperIndex);
end
