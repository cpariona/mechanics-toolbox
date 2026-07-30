function result = selectJointModel(normalized, config)
%SELECTJOINTMODEL Fit and select a joint constitutive model.
arguments
    normalized (1,1) struct
    config (1,1) struct = mechanics.config.jointMaterialCharacterizationConfig()
end

modelNames = lower(strtrim(string(config.candidateModelNames(:))));
if isempty(modelNames) || any(strlength(modelNames) == 0) || ...
        numel(unique(modelNames)) ~= numel(modelNames)
    error("mechanics:workflow:InvalidJointCandidateModels", ...
        "Joint candidate model names must be nonempty and unique.");
end
selection = localSelectionConfig(config, modelNames);

candidateCount = numel(modelNames);
candidates = repmat(struct( ...
    "modelName", "", ...
    "status", "failed", ...
    "fit", struct(), ...
    "errorIdentifier", "", ...
    "errorMessage", ""), candidateCount, 1);
modelName = modelNames;
status = strings(candidateCount, 1);
converged = false(candidateCount, 1);
eligible = false(candidateCount, 1);
practicallyEquivalent = false(candidateCount, 1);
parameterCount = nan(candidateCount, 1);
objective = inf(candidateCount, 1);
physicalSSE = inf(candidateCount, 1);
observationCount = repmat(normalized.observationCount, candidateCount, 1);
aic = inf(candidateCount, 1);
bic = inf(candidateCount, 1);
configuredOrder = zeros(candidateCount, 1);

for candidateIndex = 1:candidateCount
    candidates(candidateIndex).modelName = modelName(candidateIndex);
    configuredOrder(candidateIndex) = localConfiguredOrder( ...
        modelName(candidateIndex), selection.tieBreakOrder);
    try
        fit = mechanics.fitting.fitJointModel( ...
            normalized, modelName(candidateIndex), config);
        model = mechanics.models.modelRegistry(modelName(candidateIndex));
        [sse, count] = localPhysicalError(fit.specimens);
        criteria = localInformationCriteria(sse, count, numel(model.parameterNames));

        candidates(candidateIndex).status = "completed";
        candidates(candidateIndex).fit = fit;
        status(candidateIndex) = "completed";
        converged(candidateIndex) = fit.converged;
        parameterCount(candidateIndex) = numel(model.parameterNames);
        objective(candidateIndex) = fit.objective;
        physicalSSE(candidateIndex) = sse;
        observationCount(candidateIndex) = count;
        aic(candidateIndex) = criteria.AIC;
        bic(candidateIndex) = criteria.BIC;
        eligible(candidateIndex) = isfinite(fit.objective) && ...
            (~selection.requireConvergence || fit.converged);
    catch exception
        candidates(candidateIndex).errorIdentifier = string(exception.identifier);
        candidates(candidateIndex).errorMessage = string(exception.message);
        status(candidateIndex) = "failed";
    end
end

if ~any(eligible)
    error("mechanics:workflow:NoEligibleJointModel", ...
        "No configured joint candidate produced an eligible fit.");
end

bestObjective = min(objective(eligible));
objectiveThreshold = bestObjective + ...
    selection.practicalObjectiveTolerance * max(bestObjective, sqrt(eps));
practicallyEquivalent = eligible & objective <= objectiveThreshold;
selectedIndex = localSelectCandidate( ...
    practicallyEquivalent, parameterCount, objective, configuredOrder);

candidateSummary = table(modelName, status, converged, eligible, ...
    practicallyEquivalent, parameterCount, objective, physicalSSE, ...
    observationCount, aic, bic, configuredOrder, ...
    'VariableNames', {'ModelName','Status','Converged','Eligible', ...
    'PracticallyEquivalent','ParameterCount','Objective','PhysicalSSE', ...
    'ObservationCount','AIC','BIC','ConfiguredOrder'});

result.modeNames = normalized.modeNames;
result.candidates = candidates;
result.candidateSummary = candidateSummary;
result.selectedModelName = modelName(selectedIndex);
result.selectedFit = candidates(selectedIndex).fit;
result.selection = selection;
result.selection.bestObjective = bestObjective;
result.selection.objectiveThreshold = objectiveThreshold;
result.config = config;
result.createdAt = datetime("now");
end

function selection = localSelectionConfig(config, modelNames)
if ~isfield(config, "selection") || ~isstruct(config.selection)
    error("mechanics:workflow:MissingJointSelectionConfig", ...
        "Joint characterization config must contain a selection section.");
end
selection = config.selection;
if ~isfield(selection, "requireConvergence") || ...
        ~isscalar(selection.requireConvergence)
    error("mechanics:workflow:InvalidJointConvergenceRequirement", ...
        "selection.requireConvergence must be scalar logical-like.");
end
selection.requireConvergence = logical(selection.requireConvergence);
if ~isfield(selection, "practicalObjectiveTolerance") || ...
        ~isscalar(selection.practicalObjectiveTolerance) || ...
        ~isfinite(selection.practicalObjectiveTolerance) || ...
        selection.practicalObjectiveTolerance < 0
    error("mechanics:workflow:InvalidJointObjectiveTolerance", ...
        "selection.practicalObjectiveTolerance must be finite and nonnegative.");
end
if ~isfield(selection, "tieBreakOrder") || isempty(selection.tieBreakOrder)
    selection.tieBreakOrder = modelNames;
end
selection.tieBreakOrder = lower(strtrim(string(selection.tieBreakOrder(:))));
if any(strlength(selection.tieBreakOrder) == 0) || ...
        numel(unique(selection.tieBreakOrder)) ~= numel(selection.tieBreakOrder) || ...
        ~all(ismember(modelNames, selection.tieBreakOrder))
    error("mechanics:workflow:InvalidJointTieBreakOrder", ...
        "selection.tieBreakOrder must contain every candidate exactly once or more without duplicates.");
end
end

function order = localConfiguredOrder(modelName, tieBreakOrder)
order = find(tieBreakOrder == modelName, 1, "first");
end

function [sse, count] = localPhysicalError(specimens)
sse = 0;
count = 0;
for specimenIndex = 1:numel(specimens)
    residual = specimens(specimenIndex).Residuals(:);
    sse = sse + sum(residual.^2);
    count = count + numel(residual);
end
end

function criteria = localInformationCriteria(sse, observationCount, parameterCount)
variance = max(sse / observationCount, eps);
criteria.AIC = observationCount * log(variance) + 2 * parameterCount;
criteria.BIC = observationCount * log(variance) + ...
    parameterCount * log(observationCount);
end

function selectedIndex = localSelectCandidate(equivalent, parameterCount, objective, order)
indices = find(equivalent);
ranking = [parameterCount(indices), objective(indices), order(indices)];
[~, localOrder] = sortrows(ranking, [1, 2, 3]);
selectedIndex = indices(localOrder(1));
end