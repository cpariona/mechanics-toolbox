function config = compressionStudyConfig()
%COMPRESSIONSTUDYCONFIG Configure one multi-specimen compression study.
config.defaultInitialLength = 25;
config.continueOnError = true;
config.specimen = mechanics.config.compressionSpecimenConfig();
config.population.enabled = true;
config.population.continueOnError = true;
config.population.config = mechanics.config.populationAnalysisConfig();
end
