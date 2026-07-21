function config = fitIdentifiabilityConfig()
%FITIDENTIFIABILITYCONFIG Default diagnostics for parameter identifiability.
config.coefficientOfVariationThreshold = 0.50;
config.relativeIntervalWidthThreshold = 1.00;
config.correlationThreshold = 0.95;
config.boundaryToleranceFraction = 0.01;
config.boundaryHitFractionThreshold = 0.10;
config.normalizationFloor = sqrt(eps);
config.minimumSuccessfulSamples = 20;
end
