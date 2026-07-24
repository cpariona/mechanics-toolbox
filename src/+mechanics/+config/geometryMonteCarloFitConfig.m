function config = geometryMonteCarloFitConfig()
%GEOMETRYMONTECARLOFITCONFIG Configuration for measurement-aware fit uncertainty.
config.enabled = false;
config.sampleCount = 200;
config.confidenceLevel = 0.95;
config.randomSeed = 1;
config.minimumSuccessfulFraction = 0.8;
config.initialLengthStd = NaN;
config.initialAreaStd = NaN;
config.forceStd = NaN;
config.displacementStd = NaN;
config.refitNumberOfStarts = 2;
config.storeFits = false;
end
