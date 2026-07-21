function config = groupParameterInferenceConfig()
%GROUPPARAMETERINFERENCECONFIG Configure pairwise parameter inference.
config.alpha = 0.05;
config.permutationCount = 2000;
config.bootstrapCount = 2000;
config.randomSeed = 1;
config.minimumSpecimensPerGroup = 3;
config.multipleComparisonMethod = "benjamini-hochberg";
config.continueOnComparisonError = true;
config.requireFiniteValues = true;
end
