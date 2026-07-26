function config = compressionStudyConfig()
%COMPRESSIONSTUDYCONFIG Configure one multi-specimen compression study.
config.input.type = "auto";
config.extraction = mechanics.config.workbookExtractionConfig();
config.defaultInitialLength = 25;
config.continueOnError = true;
config.specimen = mechanics.config.compressionSpecimenConfig();

config.specimens.excludeIndices = [];
config.specimens.exclusionReason = "manual exclusion";
config.specimens.preloadForceOverrides = [];

config.population.enabled = true;
config.population.continueOnError = true;
config.population.config = mechanics.config.populationAnalysisConfig();
end
