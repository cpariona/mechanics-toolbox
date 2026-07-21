function config = fitWindowStabilityConfig()
%FITWINDOWSTABILITYCONFIG Default configuration for fit-window stability.
config.windowFractions = [0.25, 0.40, 0.55, 0.70, 0.85, 1.00];
config.minimumObservations = 8;
config.minimumSuccessfulWindows = 3;
config.relativeParameterRangeThreshold = 0.50;
config.referenceMode = "full-window";
config.continueOnFitError = true;
config.normalizationFloor = sqrt(eps);
end
