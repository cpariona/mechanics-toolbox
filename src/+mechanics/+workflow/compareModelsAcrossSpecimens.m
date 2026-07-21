function batch = compareModelsAcrossSpecimens( ...
        specimens, modelNames, fitConfig, config)
%COMPAREMODELSACROSSSPECIMENS Compare candidate models for many specimens.
arguments
    specimens (1,:) struct
    modelNames
    fitConfig (1,1) struct = mechanics.config.fittingConfig()
    config (1,1) struct = mechanics.config.batchModelComparisonConfig()
end

required = {'specimenId','deformation','measuredStress'};
for index = 1:numel(specimens)
    if ~all(isfield(specimens(index), required))
        error('mechanics:workflow:InvalidBatchSpecimen', ...
            'Each specimen requires specimenId, deformation, and measuredStress.');
    end
end

specimenCount = numel(specimens);
comparisons = cell(specimenCount, 1);
specimenId = strings(specimenCount, 1);
group = strings(specimenCount, 1);
success = false(specimenCount, 1);
hasSelectedModel = false(specimenCount, 1);
selectedModelName = strings(specimenCount, 1);
selectedCriterionValue = nan(specimenCount, 1);
errorIdentifier = strings(specimenCount, 1);
errorMessage = strings(specimenCount, 1);

for index = 1:specimenCount
    specimen = specimens(index);
    specimenId(index) = string(specimen.specimenId);
    if isfield(specimen, 'group')
        group(index) = string(specimen.group);
    end
    context = struct();
    if isfield(specimen, 'context')
        context = specimen.context;
    end

    try
        comparison = mechanics.workflow.compareModelsWithDiagnostics( ...
            modelNames, specimen.deformation, specimen.measuredStress, ...
            context, fitConfig, config.comparisonConfig);
        comparisons{index} = comparison;
        success(index) = true;
        hasSelectedModel(index) = logical(comparison.hasSelectedModel);
        if comparison.hasSelectedModel
            selectedModelName(index) = string(comparison.selectedModelName);
            selectedCriterionValue(index) = comparison.summary.CriterionValue( ...
                comparison.selectedIndex);
        elseif config.requireSelectedModel
            error('mechanics:workflow:NoSelectedBatchModel', ...
                'No eligible model was selected for specimen %s.', specimenId(index));
        end
    catch ME
        errorIdentifier(index) = string(ME.identifier);
        errorMessage(index) = string(ME.message);
        if ~config.continueOnSpecimenError
            rethrow(ME);
        end
    end
end

successfulCount = nnz(success);
if successfulCount < config.minimumSuccessfulSpecimens
    error('mechanics:workflow:InsufficientSuccessfulSpecimens', ...
        'Only %d specimens succeeded; %d are required.', ...
        successfulCount, config.minimumSuccessfulSpecimens);
end

specimenSummary = table(specimenId, group, success, hasSelectedModel, ...
    selectedModelName, selectedCriterionValue, errorIdentifier, errorMessage, ...
    'VariableNames', {'SpecimenId','Group','Success','HasSelectedModel', ...
    'SelectedModelName','SelectedCriterionValue','ErrorIdentifier','ErrorMessage'});

selected = selectedModelName(hasSelectedModel);
if isempty(selected)
    modelSummary = table(strings(0,1), zeros(0,1), zeros(0,1), ...
        'VariableNames', {'ModelName','SelectionCount','SelectionFraction'});
else
    names = unique(selected, 'stable');
    counts = zeros(numel(names),1);
    for index = 1:numel(names)
        counts(index) = nnz(selected == names(index));
    end
    fractions = counts ./ numel(selected);
    modelSummary = table(names, counts, fractions, ...
        'VariableNames', {'ModelName','SelectionCount','SelectionFraction'});
    modelSummary = sortrows(modelSummary, 'SelectionCount', 'descend');
end

groupSummary = localGroupSummary(group, selectedModelName, hasSelectedModel, ...
    config.includeGroupSummary);

batch.modelNames = string(modelNames(:));
batch.specimenCount = specimenCount;
batch.successfulSpecimenCount = successfulCount;
batch.selectedSpecimenCount = nnz(hasSelectedModel);
batch.comparisons = comparisons;
batch.specimenSummary = specimenSummary;
batch.modelSummary = modelSummary;
batch.groupSummary = groupSummary;
batch.fitConfig = fitConfig;
batch.config = config;
batch.createdAt = datetime('now');
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
