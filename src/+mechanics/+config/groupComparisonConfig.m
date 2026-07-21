function config = groupComparisonConfig()
%GROUPCOMPARISONCONFIG Default configuration for group comparisons.
config.minimumSpecimensPerGroup = 2;
config.groupVariableName = "Group";
config.populationConfig = mechanics.config.populationAnalysisConfig();
config.bootstrap.enabled = true;
config.bootstrap.iterations = 2000;
config.bootstrap.confidenceLevel = 0.95;
config.bootstrap.randomSeed = 11;
config.export.enabled = false;
config.export.outputFolder = "results/group-comparison";
end
