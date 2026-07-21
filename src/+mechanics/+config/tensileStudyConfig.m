function config = tensileStudyConfig()
%TENSILESTUDYCONFIG Default end-to-end tensile-study configuration.
config.extraction = mechanics.config.workbookExtractionConfig();
config.datasetAnalysis = mechanics.config.datasetAnalysisConfig();

config.fracture.enabled = true;
config.fracture.config = mechanics.config.fractureAnalysisConfig();

config.population.enabled = true;
config.population.config = mechanics.config.populationAnalysisConfig();
config.population.continueOnError = true;

config.export.enabled = false;
config.export.outputFolder = "results/tensile-study";
config.export.saveAnalysisMat = true;
config.export.saveConfigurationMat = true;
config.export.saveTables = true;
end
