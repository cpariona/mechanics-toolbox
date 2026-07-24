function config = compressionPopulationConfig()
%COMPRESSIONPOPULATIONCONFIG Configuration for multi-specimen compression analysis.
config.defaultInitialLength = 25;
config.continueOnError = true;
config.studyConfig = mechanics.config.compressionStudyConfig();
config.population = mechanics.config.populationAnalysisConfig();
config.minimumSpecimensPerGroup = 2;
config.comparison.enabled = true;
config.comparison.config = mechanics.config.groupComparisonConfig();
config.export.enabled = false;
config.export.outputFolder = "results/compression-population";
config.export.saveFigures = true;
config.export.figureResolution = 150;
end
