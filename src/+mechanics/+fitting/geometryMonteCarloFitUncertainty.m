function uncertainty = geometryMonteCarloFitUncertainty(specimen, fitResult, config)
%GEOMETRYMONTECARLOFITUNCERTAINTY Propagate geometry uncertainty through refitting.
arguments
    specimen (1,1) struct
    fitResult (1,1) struct
    config (1,1) struct = mechanics.config.geometryMonteCarloFitConfig()
end

requiredSpecimen = ["processed", "geometry", "processingConfig"];
if ~all(isfield(specimen, requiredSpecimen)) || ...
        ~isfield(specimen.processed, "force") || ...
        ~isfield(specimen.processed, "displacement")
    error("mechanics:fitting:InvalidGeometryMonteCarloInput", ...
        "Specimen must contain processed force/displacement, geometry, and processingConfig.");
end

sampleCount = round(config.sampleCount);
if sampleCount < 2
    error("mechanics:fitting:InvalidMonteCarloSampleCount", ...
        "sampleCount must be at least two.");
end
lengthStd = localStd(config.initialLengthStd, "initialLengthStd");
areaStd = localStd(config.initialAreaStd, "initialAreaStd");
if lengthStd == 0 && areaStd == 0
    error("mechanics:fitting:MissingMonteCarloGeometryUncertainty", ...
        "At least one positive geometry standard uncertainty is required.");
end

mechanicsConfig = specimen.processingConfig.mechanics;
if isfield(mechanicsConfig, "areaEvolution") && ...
        string(mechanicsConfig.areaEvolution) == "measured-area" && areaStd > 0
    error("mechanics:fitting:MeasuredAreaMonteCarloUnsupported", ...
        "initialAreaStd cannot perturb a measured-area stress calculation.");
end

parameterCount = numel(fitResult.parameters);
parameterSamples = nan(sampleCount, parameterCount);
successMask = false(sampleCount, 1);
if config.storeFits
    fits = cell(sampleCount, 1);
else
    fits = {};
end

rng(config.randomSeed, "twister");
refitConfig = fitResult.config;
refitConfig.initialGuess = fitResult.parameters;
refitConfig.numberOfStarts = config.refitNumberOfStarts;
refitConfig.weights = [];

baseGeometry = specimen.geometry;
xMin = min(fitResult.deformation);
xMax = max(fitResult.deformation);
for index = 1:sampleCount
    geometry = baseGeometry;
    geometry.initialLength = localPositiveNormal(baseGeometry.initialLength, lengthStd);
    geometry.initialArea = localPositiveNormal(baseGeometry.initialArea, areaStd);
    try
        curve = mechanics.analysis.computeUniaxialMeasures( ...
            specimen.processed, geometry, mechanicsConfig);
        x = curve.strain(:);
        y = curve.stress(:);
        mask = isfinite(x) & isfinite(y) & x >= xMin & x <= xMax;
        refitConfig.randomSeed = config.randomSeed + index;
        refit = mechanics.fitting.fitModel( ...
            fitResult.modelName, x(mask), y(mask), fitResult.context, refitConfig);
        parameterSamples(index, :) = refit.parameters;
        successMask(index) = true;
        if config.storeFits
            fits{index} = refit;
        end
    catch
        % Failed samples remain NaN and are reported through success metrics.
    end
end

successfulFraction = nnz(successMask) ./ sampleCount;
if successfulFraction < config.minimumSuccessfulFraction
    error("mechanics:fitting:InsufficientMonteCarloSuccess", ...
        "Only %.1f%% of geometry Monte Carlo refits succeeded.", ...
        100 .* successfulFraction);
end

valid = parameterSamples(successMask, :);
alpha = (1 - config.confidenceLevel) ./ 2;
uncertainty.modelName = fitResult.modelName;
uncertainty.parameterNames = fitResult.parameterNames;
uncertainty.baseParameters = fitResult.parameters;
uncertainty.parameterSamples = parameterSamples;
uncertainty.parameterLower = localPercentile(valid, alpha);
uncertainty.parameterMedian = localPercentile(valid, 0.5);
uncertainty.parameterUpper = localPercentile(valid, 1 - alpha);
uncertainty.successMask = successMask;
uncertainty.successfulCount = nnz(successMask);
uncertainty.successfulFraction = successfulFraction;
uncertainty.confidenceLevel = config.confidenceLevel;
uncertainty.config = config;
uncertainty.fits = fits;
end

function value = localStd(value, name)
if isempty(value) || (isscalar(value) && isnan(value))
    value = 0;
elseif ~isscalar(value) || ~isfinite(value) || value < 0
    error("mechanics:fitting:InvalidMonteCarloGeometryUncertainty", ...
        "%s must be NaN or a nonnegative finite scalar.", name);
end
end

function value = localPositiveNormal(meanValue, standardDeviation)
if standardDeviation == 0
    value = meanValue;
    return;
end
value = meanValue + standardDeviation .* randn();
while value <= 0
    value = meanValue + standardDeviation .* randn();
end
end

function values = localPercentile(data, probability)
values = nan(1, size(data, 2));
for column = 1:size(data, 2)
    vector = sort(data(:, column));
    position = 1 + (numel(vector) - 1) .* probability;
    lowerIndex = floor(position);
    upperIndex = ceil(position);
    weight = position - lowerIndex;
    values(column) = (1 - weight) .* vector(lowerIndex) + ...
        weight .* vector(upperIndex);
end
end
