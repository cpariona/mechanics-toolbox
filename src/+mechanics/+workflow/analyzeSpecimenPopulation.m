function population = analyzeSpecimenPopulation(datasetAnalysis, config)
%ANALYZESPECIMENPOPULATION Aggregate processed replicate-level results.
arguments
    datasetAnalysis (1,1) struct
    config (1,1) struct = mechanics.config.populationAnalysisConfig()
end

if ~isfield(datasetAnalysis, "records") || ...
        ~isfield(datasetAnalysis, "summary")
    error("mechanics:workflow:InvalidDatasetAnalysis", ...
        "Dataset analysis must contain records and summary.");
end

processedMask = [datasetAnalysis.records.status] == "processed";
processedRecords = datasetAnalysis.records(processedMask);

if numel(processedRecords) < config.minimumSpecimens
    error("mechanics:workflow:InsufficientProcessedSpecimens", ...
        "At least %d processed specimens are required.", ...
        config.minimumSpecimens);
end

specimenCells = arrayfun( ...
    @(record) {record.specimen}, processedRecords);
specimens = [specimenCells{:}];

population.curves = mechanics.statistics.aggregateStressStrain( ...
    specimens, config);
population.metrics = mechanics.statistics.summarizePopulationMetrics( ...
    datasetAnalysis.summary, config);
population.modelParameters = ...
    mechanics.statistics.summarizeSelectedModelParameters( ...
        processedRecords, config);
population.specimenIds = string({processedRecords.specimenId})';
population.specimenCount = numel(processedRecords);
population.config = config;
population.createdAt = datetime("now");

if config.export.enabled
    population.outputFiles = mechanics.io.exportPopulationAnalysis( ...
        population, config.export.outputFolder);
end
end
