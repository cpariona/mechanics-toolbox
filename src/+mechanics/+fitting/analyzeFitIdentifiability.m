function diagnostics = analyzeFitIdentifiability(fitResult, uncertainty, config)
%ANALYZEFITIDENTIFIABILITY Diagnose parameter uncertainty and dependence.
arguments
    fitResult (1,1) struct
    uncertainty (1,1) struct
    config (1,1) struct = mechanics.config.fitIdentifiabilityConfig()
end

requiredFit = ["parameters", "parameterNames", "config"];
requiredUncertainty = ["parameterSamples", "successMask", ...
    "parameterLower", "parameterUpper", "successfulCount"];

if ~all(isfield(fitResult, requiredFit)) || ...
        ~all(isfield(uncertainty, requiredUncertainty))
    error("mechanics:fitting:InvalidIdentifiabilityInput", ...
        "fitResult or uncertainty is missing required fields.");
end

if uncertainty.successfulCount < config.minimumSuccessfulSamples
    error("mechanics:fitting:InsufficientIdentifiabilitySamples", ...
        "At least %d successful bootstrap samples are required.", ...
        config.minimumSuccessfulSamples);
end

samples = uncertainty.parameterSamples(uncertainty.successMask, :);
parameterNames = string(fitResult.parameterNames(:));
baseParameters = fitResult.parameters(:);

if size(samples, 2) ~= numel(baseParameters)
    error("mechanics:fitting:IdentifiabilitySizeMismatch", ...
        "Bootstrap samples must match the fitted parameter count.");
end

sampleMean = mean(samples, 1, "omitnan")';
sampleStandardDeviation = std(samples, 0, 1, "omitnan")';
normalization = max(abs(sampleMean), config.normalizationFloor);
coefficientOfVariation = sampleStandardDeviation ./ normalization;

intervalWidth = uncertainty.parameterUpper(:) - ...
    uncertainty.parameterLower(:);
relativeIntervalWidth = intervalWidth ./ ...
    max(abs(baseParameters), config.normalizationFloor);

lowerBounds = fitResult.config.lowerBounds(:);
upperBounds = fitResult.config.upperBounds(:);
parameterCount = numel(baseParameters);
lowerBoundaryHitFraction = zeros(parameterCount, 1);
upperBoundaryHitFraction = zeros(parameterCount, 1);

for index = 1:parameterCount
    lower = lowerBounds(index);
    upper = upperBounds(index);
    span = upper - lower;

    if isfinite(lower) && isfinite(upper)
        tolerance = config.boundaryToleranceFraction * span;
    else
        tolerance = config.boundaryToleranceFraction * ...
            max(abs(baseParameters(index)), 1);
    end

    if isfinite(lower)
        lowerBoundaryHitFraction(index) = mean( ...
            samples(:, index) <= lower + tolerance);
    end
    if isfinite(upper)
        upperBoundaryHitFraction(index) = mean( ...
            samples(:, index) >= upper - tolerance);
    end
end

maximumBoundaryHitFraction = max( ...
    lowerBoundaryHitFraction, upperBoundaryHitFraction);

weakByVariation = coefficientOfVariation > ...
    config.coefficientOfVariationThreshold;
weakByInterval = relativeIntervalWidth > ...
    config.relativeIntervalWidthThreshold;
weakByBoundary = maximumBoundaryHitFraction > ...
    config.boundaryHitFractionThreshold;
parameterFlag = weakByVariation | weakByInterval | weakByBoundary;

if parameterCount == 1
    correlationMatrix = 1;
else
    correlationMatrix = corrcoef(samples, "Rows", "pairwise");
end

pairRows = {};
for row = 1:parameterCount
    for column = row + 1:parameterCount
        correlation = correlationMatrix(row, column);
        if isfinite(correlation) && ...
                abs(correlation) >= config.correlationThreshold
            pairRows(end + 1, :) = { ... %#ok<AGROW>
                parameterNames(row), parameterNames(column), correlation};
        end
    end
end

if isempty(pairRows)
    highCorrelationPairs = table( ...
        strings(0,1), strings(0,1), zeros(0,1), ...
        'VariableNames', {"Parameter1", "Parameter2", "Correlation"});
else
    highCorrelationPairs = cell2table(pairRows, ...
        'VariableNames', {"Parameter1", "Parameter2", "Correlation"});
    highCorrelationPairs.Parameter1 = string(highCorrelationPairs.Parameter1);
    highCorrelationPairs.Parameter2 = string(highCorrelationPairs.Parameter2);
end

parameterSummary = table( ...
    parameterNames, baseParameters, sampleMean, sampleStandardDeviation, ...
    coefficientOfVariation, intervalWidth, relativeIntervalWidth, ...
    lowerBoundaryHitFraction, upperBoundaryHitFraction, ...
    maximumBoundaryHitFraction, weakByVariation, weakByInterval, ...
    weakByBoundary, parameterFlag, ...
    'VariableNames', { ...
        "Parameter", "BestFit", "BootstrapMean", ...
        "BootstrapStandardDeviation", "CoefficientOfVariation", ...
        "IntervalWidth", "RelativeIntervalWidth", ...
        "LowerBoundaryHitFraction", "UpperBoundaryHitFraction", ...
        "MaximumBoundaryHitFraction", "WeakByVariation", ...
        "WeakByInterval", "WeakByBoundary", "WeaklyIdentified"});

diagnostics.modelName = fitResult.modelName;
diagnostics.parameterSummary = parameterSummary;
diagnostics.correlationMatrix = correlationMatrix;
diagnostics.highCorrelationPairs = highCorrelationPairs;
diagnostics.hasHighCorrelation = ~isempty(highCorrelationPairs);
diagnostics.hasWeakParameter = any(parameterFlag);
diagnostics.weaklyIdentified = ...
    diagnostics.hasWeakParameter || diagnostics.hasHighCorrelation;
diagnostics.successfulSampleCount = uncertainty.successfulCount;
diagnostics.config = config;
end
