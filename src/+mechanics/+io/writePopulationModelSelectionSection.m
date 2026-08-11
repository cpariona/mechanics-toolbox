function writePopulationModelSelectionSection(fileId, population)
%WRITEPOPULATIONMODELSELECTIONSECTION Write maintained population model-selection summary.
arguments
    fileId (1,1) double
    population (1,1) struct
end

if ~isfield(population, "modelSelection") || ...
        ~isfield(population.modelSelection, "summary") || ...
        isempty(population.modelSelection.summary)
    return;
end

selection = population.modelSelection;
summary = selection.summary;
if ismember("ModelName", string(summary.Properties.VariableNames))
    names = string(summary.ModelName(:));
    for index = 1:numel(names)
        if strlength(names(index)) > 0
            names(index) = mechanics.models.modelRegistry(names(index)).displayName;
        end
    end
    summary.ModelName = names;
end

fprintf(fileId, "### Individual model-selection consensus\n\n");
mechanics.io.writeMarkdownTable(fileId, summary);

if ~isfield(selection, "hasConsensusModel") || ~selection.hasConsensusModel
    if isfield(selection, "reason") && strlength(string(selection.reason)) > 0
        fprintf(fileId, "%s\n\n", char(string(selection.reason)));
    end
    return;
end

modelName = mechanics.models.modelRegistry( ...
    string(selection.consensusModelName)).displayName;
fprintf(fileId, "Selection consensus: `%s` (%d/%d, %.1f%%).\n\n", ...
    char(modelName), selection.consensusSelectionCount, ...
    selection.selectedSpecimenCount, ...
    100 .* selection.consensusSelectionFraction);

if isfield(selection, "unanimous") && selection.unanimous
    fprintf(fileId, ...
        "All eligible specimens selected the same model. The individually selected-model parameter population therefore already represents the selection-consensus model population; no separate consensus refit is required for the standard study report.\n\n");
else
    fprintf(fileId, ...
        "The selection consensus is descriptive only: it is the unique most frequently selected model across eligible specimens. Parameter summaries below retain each specimen's individually selected model and no population refit is performed by the standard study workflow.\n\n");
end
end
