function config = populationAnalysisConfig()
%POPULATIONANALYSISCONFIG Default configuration for replicate aggregation.
config.minimumSpecimens = 2;
config.strainGridPointCount = 201;
config.strainRangeMode = "common-overlap";
config.explicitStrainRange = [NaN, NaN];
config.centralStatistic = "mean";

config.bootstrap.enabled = true;
config.bootstrap.iterations = 1000;
config.bootstrap.confidenceLevel = 0.95;
config.bootstrap.randomSeed = 1;

config.export.enabled = false;
config.export.outputFolder = "results/population";
end