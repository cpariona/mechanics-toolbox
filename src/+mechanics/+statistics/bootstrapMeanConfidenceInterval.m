function result = bootstrapMeanConfidenceInterval(values, config)
%BOOTSTRAPMEANCONFIDENCEINTERVAL Bootstrap a mean and percentile interval.
arguments
    values {mustBeNumeric, mustBeReal}
    config (1,1) struct
end

values = values(:);
values = values(isfinite(values));

if isempty(values)
    error("mechanics:statistics:NoFiniteData", ...
        "At least one finite value is required.");
end

if ~isscalar(config.iterations) || ...
        ~isfinite(config.iterations) || ...
        config.iterations < 1
    error("mechanics:statistics:InvalidBootstrapIterations", ...
        "Bootstrap iterations must be a positive finite scalar.");
end

if ~isscalar(config.confidenceLevel) || ...
        ~isfinite(config.confidenceLevel) || ...
        config.confidenceLevel <= 0 || ...
        config.confidenceLevel >= 1
    error("mechanics:statistics:InvalidConfidenceLevel", ...
        "Confidence level must lie in the interval (0, 1).");
end

iterations = round(config.iterations);
sampleCount = numel(values);

rng(config.randomSeed, "twister");

bootstrapMeans = zeros(iterations, 1);
for iteration = 1:iterations
    indices = randi(sampleCount, sampleCount, 1);
    bootstrapMeans(iteration) = mean(values(indices));
end

alpha = 1 - config.confidenceLevel;
lowerProbability = alpha ./ 2;
upperProbability = 1 - alpha ./ 2;

result.mean = mean(values);
result.lower = localPercentile(bootstrapMeans, lowerProbability);
result.upper = localPercentile(bootstrapMeans, upperProbability);
result.bootstrapMeans = bootstrapMeans;
result.sampleCount = sampleCount;
result.confidenceLevel = config.confidenceLevel;
result.iterations = iterations;
end

function value = localPercentile(samples, probability)
samples = sort(samples(:));
sampleCount = numel(samples);

if sampleCount == 1
    value = samples(1);
    return;
end

position = 1 + probability .* (sampleCount - 1);
lowerIndex = floor(position);
upperIndex = ceil(position);

if lowerIndex == upperIndex
    value = samples(lowerIndex);
else
    fraction = position - lowerIndex;
    value = samples(lowerIndex) .* (1 - fraction) + ...
        samples(upperIndex) .* fraction;
end
end
