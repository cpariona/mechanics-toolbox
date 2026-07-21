function config = fittingConfig()
%FITTINGCONFIG Return default configuration for hyperelastic fitting.
config.initialGuess = [];
config.lowerBounds = [];
config.upperBounds = [];
config.numberOfStarts = 8;
config.randomSeed = 1;
config.maxIterations = 3000;
config.maxFunctionEvaluations = 10000;
config.functionTolerance = 1e-10;
config.parameterTolerance = 1e-10;
config.display = "off";
config.weights = [];
config.normalizationFloor = eps;
end
