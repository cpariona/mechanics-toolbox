function config = selectedParameterPopulationConfig()
%SELECTEDPARAMETERPOPULATIONCONFIG Configure selected-model parameter summaries.
config.includeGroupSummary = true;
config.minimumSpecimensPerSummary = 2;
config.requireFiniteParameters = true;
config.continueOnExtractionError = true;
end