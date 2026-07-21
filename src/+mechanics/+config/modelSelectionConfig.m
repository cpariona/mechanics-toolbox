function config = modelSelectionConfig()
%MODELSELECTIONCONFIG Default configuration for robust model selection.
config.windowFractions = [0.50, 0.75, 1.00];
config.minimumObservations = 12;
config.rankingMetric = "BIC";
config.requireConvergence = true;
config.maximumRelativeParameterCV = 0.50;
config.relativeScaleFloor = 1e-12;
config.informationCriterionTolerance = 2.0;
config.rmseRelativeTolerance = 1e-6;
config.rmseAbsoluteTolerance = 1e-8;
end
