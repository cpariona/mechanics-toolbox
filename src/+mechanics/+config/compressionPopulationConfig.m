function config = compressionPopulationConfig()
%COMPRESSIONPOPULATIONCONFIG Configuration for multi-specimen compression analysis.
config.defaultInitialLength = 25;
config.continueOnError = true;
config.studyConfig = mechanics.config.compressionStudyConfig();
config.population = mechanics.config.populationAnalysisConfig();
config.minimumSpecimensPerGroup = 2;
config.export.enabled = false;
config.export.outputFolder = "results/compression-population";
end
