function config = selectedParameterPopulationConfig()
%SELECTEDPARAMETERPOPULATIONCONFIG Configure selected-model parameter summaries.
config.includeGroupSummary = true;
config.minimumSpecimensPerSummary = 1;
config.requireFiniteParameters = true;
config.continueOnExtractionError = true;
end
