function config = fitUncertaintyConfig()
%FITUNCERTAINTYCONFIG Default bootstrap uncertainty configuration.
config.sampleCount = 200;
config.confidenceLevel = 0.95;
config.randomSeed = 1;
config.method = "residual";
config.minimumSuccessfulFraction = 0.80;
config.refitNumberOfStarts = 1;
config.predictionDeformation = [];
config.storeBootstrapFits = false;
end
