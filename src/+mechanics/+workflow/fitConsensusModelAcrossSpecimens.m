function batch = fitConsensusModelAcrossSpecimens( ...
        specimens, selectedModelNames, candidateModelNames, fitConfig)
%FITCONSENSUSMODELACROSSSPECIMENS Refit all specimens with one consensus model.
arguments
    specimens (1,:) struct
    selectedModelNames string
    candidateModelNames string
    fitConfig (1,1) struct = mechanics.config.fittingConfig()
end

selectedModelNames = selectedModelNames(:);
selectedModelNames = selectedModelNames(strlength(selectedModelNames) > 0);
if isempty(selectedModelNames)
    error("mechanics:workflow:MissingConsensusSelections", ...
        "At least one standard-workflow model selection is required.");
end

candidateModelNames = candidateModelNames(:);
selectionCount = zeros(numel(candidateModelNames), 1);
for index = 1:numel(candidateModelNames)
    selectionCount(index) = nnz(selectedModelNames == candidateModelNames(index));
end
maximumCount = max(selectionCount);
consensusIndex = find(selectionCount == maximumCount, 1, "first");
consensusModel = candidateModelNames(consensusIndex);
selectionFraction = selectionCount ./ numel(selectedModelNames);
modelSummary = table(candidateModelNames, selectionCount, selectionFraction, ...
    candidateModelNames == consensusModel, ...
    'VariableNames', {'ModelName','SelectionCount','SelectionFraction','Consensus'});

specimenCount = numel(specimens);
selectedFits = cell(specimenCount, 1);
specimenId = strings(specimenCount, 1);
group = strings(specimenCount, 1);
success = false(specimenCount, 1);
hasSelectedModel = false(specimenCount, 1);
selectedModelName = repmat(consensusModel, specimenCount, 1);
selectedCriterionValue = nan(specimenCount, 1);
errorIdentifier = strings(specimenCount, 1);
errorMessage = strings(specimenCount, 1);

for index = 1:specimenCount
    specimen = specimens(index);
    specimenId(index) = string(specimen.specimenId);
    if isfield(specimen, "group")
        group(index) = string(specimen.group);
    end
    context = struct();
    if isfield(specimen, "context")
        context = specimen.context;
    end
    try
        selectedFits{index} = mechanics.fitting.fitModel( ...
            consensusModel, specimen.deformation, specimen.measuredStress, ...
            context, fitConfig);
        success(index) = true;
        hasSelectedModel(index) = true;
    catch ME
        errorIdentifier(index) = string(ME.identifier);
        errorMessage(index) = string(ME.message);
    end
end

specimenSummary = table(specimenId, group, success, hasSelectedModel, ...
    selectedModelName, selectedCriterionValue, errorIdentifier, errorMessage, ...
    'VariableNames', {'SpecimenId','Group','Success','HasSelectedModel', ...
    'SelectedModelName','SelectedCriterionValue','ErrorIdentifier','ErrorMessage'});

batch.modelNames = candidateModelNames;
batch.consensusModelName = consensusModel;
batch.specimenCount = specimenCount;
batch.successfulSpecimenCount = nnz(success);
batch.selectedSpecimenCount = nnz(hasSelectedModel);
batch.selectedFits = selectedFits;
batch.specimenSummary = specimenSummary;
batch.modelSummary = modelSummary;
batch.groupSummary = table();
batch.fitConfig = fitConfig;
batch.createdAt = datetime("now");
end