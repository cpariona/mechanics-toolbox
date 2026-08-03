function result = selectTensileApplicationRangeModel(candidates, config)
%SELECTTENSILEAPPLICATIONRANGEMODEL Select a parsimonious fitted candidate.
arguments
    candidates (:,1) struct
    config (1,1) struct = ...
        mechanics.config.tensileApplicationRangeCharacterizationConfig()
end

selection = localSelectionConfig(config);
candidateCount = numel(candidates);
if candidateCount < 1
    error("mechanics:workflow:EmptyTensileApplicationRangeCandidates", ...
        "Provide at least one fitted candidate record.");
end

modelName = strings(candidateCount, 1);
status = strings(candidateCount, 1);
converged = false(candidateCount, 1);
eligible = false(candidateCount, 1);
practicallyEquivalent = false(candidateCount, 1);
parameterCount = nan(candidateCount, 1);
objective = inf(candidateCount, 1);
configuredOrder = inf(candidateCount, 1);

for candidateIndex = 1:candidateCount
    candidate = candidates(candidateIndex);
    localValidateCandidate(candidate, candidateIndex);
    modelName(candidateIndex) = lower(strtrim(string(candidate.modelName)));
    status(candidateIndex) = string(candidate.status);
    configuredOrder(candidateIndex) = localConfiguredOrder( ...
        modelName(candidateIndex), selection.tieBreakOrder);

    if status(candidateIndex) ~= "completed"
        continue
    end

    model = mechanics.models.modelRegistry(modelName(candidateIndex));
    parameterCount(candidateIndex) = numel(model.parameterNames);
    objective(candidateIndex) = double(candidate.objective);
    converged(candidateIndex) = logical(candidate.converged);
    eligible(candidateIndex) = isfinite(objective(candidateIndex)) && ...
        (~selection.requireConvergence || converged(candidateIndex));
end

if numel(unique(modelName)) ~= candidateCount
    error("mechanics:workflow:DuplicateTensileApplicationRangeCandidates", ...
        "Candidate model names must be unique.");
end
if ~any(eligible)
    error("mechanics:workflow:NoEligibleTensileApplicationRangeModel", ...
        "No tensile application-range candidate produced an eligible fit.");
end

bestObjective = min(objective(eligible));
objectiveThreshold = bestObjective + ...
    selection.practicalObjectiveTolerance * max(bestObjective, sqrt(eps));
practicallyEquivalent = eligible & objective <= objectiveThreshold;
selectedIndex = localSelectCandidate( ...
    practicallyEquivalent, parameterCount, objective, configuredOrder);
selectedCandidate = candidates(selectedIndex);
selectedModel = mechanics.models.modelRegistry(modelName(selectedIndex));
referenceProperties = localReferenceProperties( ...
    selectedModel, selectedCandidate.fit.parameters);

candidateSummary = table(modelName, status, converged, eligible, ...
    practicallyEquivalent, parameterCount, objective, configuredOrder, ...
    'VariableNames', {'ModelName','Status','Converged','Eligible', ...
    'PracticallyEquivalent','ParameterCount','Objective','ConfiguredOrder'});

result.candidates = candidates;
result.candidateSummary = candidateSummary;
result.selectedModelName = modelName(selectedIndex);
result.selectedFit = selectedCandidate.fit;
result.referenceProperties = referenceProperties;
result.selection = selection;
result.selection.bestObjective = bestObjective;
result.selection.objectiveThreshold = objectiveThreshold;
result.config = config;
result.createdAt = datetime("now");
end

function selection = localSelectionConfig(config)
if ~isfield(config, "selection") || ~isstruct(config.selection)
    error("mechanics:workflow:MissingTensileApplicationRangeSelectionConfig", ...
        "Application-range config must contain a selection section.");
end
selection = config.selection;
if ~isfield(selection, "requireConvergence") || ...
        ~isscalar(selection.requireConvergence)
    error("mechanics:workflow:InvalidTensileApplicationRangeConvergenceRequirement", ...
        "selection.requireConvergence must be scalar logical-like.");
end
selection.requireConvergence = logical(selection.requireConvergence);
if ~isfield(selection, "practicalObjectiveTolerance") || ...
        ~isscalar(selection.practicalObjectiveTolerance) || ...
        ~isfinite(selection.practicalObjectiveTolerance) || ...
        selection.practicalObjectiveTolerance < 0
    error("mechanics:workflow:InvalidTensileApplicationRangeObjectiveTolerance", ...
        "selection.practicalObjectiveTolerance must be finite and nonnegative.");
end
if ~isfield(selection, "tieBreakOrder") || isempty(selection.tieBreakOrder)
    error("mechanics:workflow:MissingTensileApplicationRangeTieBreakOrder", ...
        "selection.tieBreakOrder must contain every candidate model.");
end
selection.tieBreakOrder = lower(strtrim(string(selection.tieBreakOrder(:))));
if any(strlength(selection.tieBreakOrder) == 0) || ...
        numel(unique(selection.tieBreakOrder)) ~= numel(selection.tieBreakOrder)
    error("mechanics:workflow:InvalidTensileApplicationRangeTieBreakOrder", ...
        "selection.tieBreakOrder must contain unique nonempty model names.");
end
end

function localValidateCandidate(candidate, candidateIndex)
required = ["modelName", "status", "fit", "objective", "converged"];
if ~all(isfield(candidate, required))
    error("mechanics:workflow:InvalidTensileApplicationRangeCandidate", ...
        "Candidate %d does not satisfy the D2 result contract.", candidateIndex);
end
if string(candidate.status) == "completed" && ...
        (~isstruct(candidate.fit) || ~isfield(candidate.fit, "parameters"))
    error("mechanics:workflow:InvalidTensileApplicationRangeCandidate", ...
        "Completed candidate %d does not contain fitted parameters.", ...
        candidateIndex);
end
end

function order = localConfiguredOrder(modelName, tieBreakOrder)
order = find(tieBreakOrder == modelName, 1, "first");
if isempty(order)
    error("mechanics:workflow:InvalidTensileApplicationRangeTieBreakOrder", ...
        "No configured tie-break position exists for model %s.", modelName);
end
end

function selectedIndex = localSelectCandidate(equivalent, parameterCount, objective, order)
indices = find(equivalent);
ranking = [parameterCount(indices), objective(indices), order(indices)];
[~, localOrder] = sortrows(ranking, [1, 2, 3]);
selectedIndex = indices(localOrder(1));
end

function properties = localReferenceProperties(model, parameters)
names = string(model.derivedQuantityNames(:));
if isempty(names)
    values = zeros(0, 1);
elseif isempty(model.evaluateDerivedQuantities)
    error("mechanics:models:MissingDerivedQuantityEvaluator", ...
        "Model %s declares derived quantities without an evaluator.", model.name);
else
    values = reshape(double(model.evaluateDerivedQuantities(parameters)), [], 1);
end
if numel(values) ~= numel(names) || any(~isfinite(values))
    error("mechanics:models:InvalidDerivedQuantities", ...
        "Model %s returned invalid derived quantities.", model.name);
end
properties.modelName = model.name;
properties.names = names;
properties.values = values;
properties.parameterNames = model.parameterNames;
properties.parameters = reshape(double(parameters), 1, []);
end
