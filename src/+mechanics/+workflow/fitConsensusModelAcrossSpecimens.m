function batch = fitConsensusModelAcrossSpecimens( ...
        specimens, individualSelectedModelNames, candidateModelNames, ...
        fitConfig, config)
%FITCONSENSUSMODELACROSSSPECIMENS Refit all specimens with the standard-selection consensus model.
arguments
    specimens (1,:) struct
    individualSelectedModelNames string
    candidateModelNames string
    fitConfig (1,1) struct = mechanics.config.fittingConfig()
    config (1,1) struct = mechanics.config.batchModelComparisonConfig()
end

required = {'specimenId','deformation','measuredStress'};
for index = 1:numel(specimens)
    if ~all(isfield(specimens(index), required))
        error("mechanics:workflow:InvalidConsensusSpecimen", ...
            "Each specimen requires specimenId, deformation, and measuredStress.");
    end
end

individualSelectedModelNames = individualSelectedModelNames(:);
if numel(individualSelectedModelNames) ~= numel(specimens)
    error("mechanics:workflow:ConsensusSelectionSizeMismatch", ...
        "One standard-workflow model selection is required per specimen.");
end
candidateModelNames = candidateModelNames(:);
validSelection = strlength(individualSelectedModelNames) > 0;
selected = individualSelectedModelNames(validSelection);
if isempty(selected)
    error("mechanics:workflow:MissingConsensusSelections", ...
        "No standard-workflow model selections were available.");
end

selectionCount = zeros(numel(candidateModelNames), 1);
for index = 1:numel(candidateModelNames)
    selectionCount(index) = nnz(selected == candidateModelNames(index));
end
maximumCount = max(selectionCount);
consensusIndex = find(selectionCount == maximumCount, 1, "first");
consensusModelName = candidateModelNames(consensusIndex);
selectionFraction = selectionCount ./ numel(selected);
modelSummary = table(candidateModelNames, selectionCount, selectionFraction, ...
    candidateModelNames == consensusModelName, ...
    'VariableNames', {'ModelName','SelectionCount','SelectionFraction','Consensus'});

specimenCount = numel(specimens);
selectedFits = cell(specimenCount, 1);
specimenId = strings(specimenCount, 1);
group = strings(specimenCount, 1);
success = false(specimenCount, 1);
hasSelectedModel = false(specimenCount, 1);
selectedModelName = repmat(consensusModelName, specimenCount, 1);
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
            consensusModelName, specimen.deformation, specimen.measuredStress, ...
            context, fitConfig);
        success(index) = true;
        hasSelectedModel(index) = true;
    catch ME
        errorIdentifier(index) = string(ME.identifier);
        errorMessage(index) = string(ME.message);
        if ~config.continueOnSpecimenError
            rethrow(ME);
        end
    end
end

if nnz(success) < config.minimumSuccessfulSpecimens
    error("mechanics:workflow:InsufficientConsensusFits", ...
        "Only %d consensus fits succeeded; %d are required.", ...
        nnz(success), config.minimumSuccessfulSpecimens);
end

specimenSummary = table(specimenId, group, success, hasSelectedModel, ...
    selectedModelName, selectedCriterionValue, errorIdentifier, errorMessage, ...
    individualSelectedModelNames, ...
    'VariableNames', {'SpecimenId','Group','Success','HasSelectedModel', ...
    'SelectedModelName','SelectedCriterionValue','ErrorIdentifier','ErrorMessage', ...
    'IndividualSelectedModelName'});

groupSummary = localGroupSummary(group, individualSelectedModelNames, ...
    validSelection, config.includeGroupSummary);

batch.modelNames = candidateModelNames;
batch.consensusModelName = consensusModelName;
batch.specimenCount = specimenCount;
batch.successfulSpecimenCount = nnz(success);
batch.selectedSpecimenCount = nnz(hasSelectedModel);
batch.selectedFits = selectedFits;
batch.specimenSummary = specimenSummary;
batch.modelSummary = modelSummary;
batch.groupSummary = groupSummary;
batch.fitConfig = fitConfig;
batch.config = config;
batch.createdAt = datetime("now");
end

function summary = localGroupSummary(group, selectedModel, hasSelection, enabled)
if ~enabled || ~any(strlength(group) > 0)
    summary = table(strings(0,1), strings(0,1), zeros(0,1), zeros(0,1), ...
        'VariableNames', {'Group','ModelName','SelectionCount','SelectionFraction'});
    return;
end
rowsGroup = strings(0,1);
rowsModel = strings(0,1);
rowsCount = zeros(0,1);
rowsFraction = zeros(0,1);
groups = unique(group(strlength(group) > 0), 'stable');
for groupIndex = 1:numel(groups)
    mask = group == groups(groupIndex) & hasSelection;
    selected = selectedModel(mask);
    names = unique(selected, 'stable');
    for modelIndex = 1:numel(names)
        rowsGroup(end+1,1) = groups(groupIndex); %#ok<AGROW>
        rowsModel(end+1,1) = names(modelIndex); %#ok<AGROW>
        rowsCount(end+1,1) = nnz(selected == names(modelIndex)); %#ok<AGROW>
        rowsFraction(end+1,1) = rowsCount(end) / numel(selected); %#ok<AGROW>
    end
end
summary = table(rowsGroup, rowsModel, rowsCount, rowsFraction, ...
    'VariableNames', {'Group','ModelName','SelectionCount','SelectionFraction'});
end