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

hasTangentModulus = arrayfun(@localHasTangentModulus, specimens);
tangentSpecimens = specimens(hasTangentModulus);
population.tangentModulus = struct();
population.tangentModulusStatus = "unavailable";
if numel(tangentSpecimens) >= config.minimumSpecimens
    population.tangentModulus = ...
        mechanics.statistics.aggregateTangentModulus( ...
            tangentSpecimens, config);
    population.tangentModulusStatus = "completed";
end

population.metrics = mechanics.statistics.summarizePopulationMetrics( ...
    datasetAnalysis.summary, config);
population.modelSelection = localSummarizeModelSelection(processedRecords);
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

function available = localHasTangentModulus(specimen)
available = isfield(specimen, "analysis") && ...
    isfield(specimen.analysis, "tangentModulus") && ...
    isfield(specimen.analysis.tangentModulus, "strain") && ...
    isfield(specimen.analysis.tangentModulus, "tangentModulusForPlot");
end

function result = localSummarizeModelSelection(records)
specimenId = strings(0,1);
selectedModel = strings(0,1);
candidateModels = strings(0,1);

for recordIndex = 1:numel(records)
    record = records(recordIndex);
    if record.status ~= "processed" || ...
            ~isfield(record.specimen, "modelSelection")
        continue;
    end

    selection = record.specimen.modelSelection;
    if isfield(selection, "records") && ~isempty(selection.records)
        candidateModels = [candidateModels; ...
            string({selection.records.modelName})']; %#ok<AGROW>
    elseif isfield(selection, "summary") && ...
            ismember("Model", string(selection.summary.Properties.VariableNames))
        candidateModels = [candidateModels; ...
            string(selection.summary.Model(:))]; %#ok<AGROW>
    end

    if ~isfield(selection, "selection") || ...
            ~isfield(selection.selection, "hasEligibleModel") || ...
            ~selection.selection.hasEligibleModel
        continue;
    end

    specimenId(end+1,1) = string(record.specimenId); %#ok<AGROW>
    selectedModel(end+1,1) = string(selection.selection.bestModel); %#ok<AGROW>
end

values = table(specimenId, selectedModel, ...
    'VariableNames', {'SpecimenId','ModelName'});
candidateModels = unique(candidateModels(strlength(candidateModels) > 0), "stable");
if isempty(candidateModels)
    candidateModels = unique(selectedModel, "stable");
end

selectionCount = zeros(numel(candidateModels),1);
for modelIndex = 1:numel(candidateModels)
    selectionCount(modelIndex) = nnz(selectedModel == candidateModels(modelIndex));
end
selectionFraction = selectionCount ./ max(numel(selectedModel), 1);
summary = table(candidateModels, selectionCount, selectionFraction, ...
    'VariableNames', {'ModelName','SelectionCount','SelectionFraction'});

result.values = values;
result.summary = summary;
result.selectedSpecimenCount = numel(selectedModel);
result.hasConsensusModel = false;
result.consensusModelName = "";
result.consensusSelectionCount = 0;
result.consensusSelectionFraction = NaN;
result.unanimous = false;
result.reason = "No eligible individual model selections were available.";

if isempty(selectedModel) || isempty(selectionCount)
    return;
end

maximumCount = max(selectionCount);
winners = find(selectionCount == maximumCount & selectionCount > 0);
if numel(winners) ~= 1
    result.reason = ...
        "No unique selection-frequency consensus exists because the leading models are tied.";
    return;
end

winner = winners(1);
result.hasConsensusModel = true;
result.consensusModelName = candidateModels(winner);
result.consensusSelectionCount = selectionCount(winner);
result.consensusSelectionFraction = selectionFraction(winner);
result.unanimous = selectionCount(winner) == numel(selectedModel);
if result.unanimous
    result.reason = ...
        "All eligible specimens selected the same constitutive model.";
else
    result.reason = ...
        "Consensus is the unique most frequently selected constitutive model; no population refit was performed.";
end
end
