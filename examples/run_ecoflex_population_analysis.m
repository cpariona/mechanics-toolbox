%RUN_ECOFLEX_POPULATION_ANALYSIS Aggregate processed Ecoflex specimens.
startup;

% Run extraction and specimen-level analysis first.
run_ecoflex_dataset_analysis

populationConfig = mechanics.config.populationAnalysisConfig();
populationConfig.strainGridPointCount = 201;
populationConfig.bootstrap.enabled = true;
populationConfig.bootstrap.iterations = 2000;
populationConfig.bootstrap.confidenceLevel = 0.95;
populationConfig.bootstrap.randomSeed = 7;

population = mechanics.workflow.analyzeSpecimenPopulation( ...
    analysis, populationConfig);

disp(population.metrics);
disp(population.modelParameters.summary);

mechanics.plotting.plotPopulationStressStrain(population);

outputFiles = mechanics.io.exportPopulationAnalysis( ...
    population, "results/ecoflex-0050/population");

disp(outputFiles);
