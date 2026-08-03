function audit = auditTensileApplicationRangeSensitivity(tensileStudy, config)
%AUDITTENSILEAPPLICATIONRANGESENSITIVITY Refit across upper range limits.
arguments
    tensileStudy (1,1) struct
    config (1,1) struct = ...
        mechanics.config.tensileApplicationRangeCharacterizationConfig()
end

maximums = localMaximums(config);
scenarioCount = numel(maximums);
scenarios = repmat(struct("maximumDeformation", NaN, "status", "failed", ...
    "normalized", struct(), "candidates", struct([]), "selection", struct(), ...
    "errorIdentifier", "", "errorMessage", ""), scenarioCount, 1);
selectedModelName = strings(scenarioCount, 1);
objective = inf(scenarioCount, 1);
mu0 = nan(scenarioCount, 1);
status = strings(scenarioCount, 1);

for index = 1:scenarioCount
    scenarioConfig = config;
    scenarioConfig.fitRange = [config.fitRange(1), maximums(index)];
    scenarios(index).maximumDeformation = maximums(index);
    try
        normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
            tensileStudy, scenarioConfig);
        candidates = mechanics.workflow.fitTensileApplicationRangeModels( ...
            normalized, scenarioConfig);
        selection = mechanics.workflow.selectTensileApplicationRangeModel( ...
            candidates, scenarioConfig);
        scenarios(index).status = "completed";
        scenarios(index).normalized = normalized;
        scenarios(index).candidates = candidates;
        scenarios(index).selection = selection;
        status(index) = "completed";
        selectedModelName(index) = selection.selectedModelName;
        objective(index) = selection.selectedFit.objective;
        mu0(index) = localMu0(selection.referenceProperties);
    catch exception
        scenarios(index).errorIdentifier = string(exception.identifier);
        scenarios(index).errorMessage = string(exception.message);
        status(index) = "failed";
    end
end

if ~any(status == "completed")
    error("mechanics:workflow:NoCompletedTensileApplicationRangeSensitivityScenario", ...
        "No configured range-sensitivity scenario completed successfully.");
end

scenarioSummary = table(maximums, status, selectedModelName, objective, mu0, ...
    'VariableNames', {'MaximumDeformation','Status','SelectedModelName', ...
    'Objective','Mu0'});

audit.maximumDeformations = maximums;
audit.scenarios = scenarios;
audit.scenarioSummary = scenarioSummary;
audit.completedScenarioCount = nnz(status == "completed");
audit.failedScenarioCount = nnz(status == "failed");
audit.config = config;
audit.createdAt = datetime("now");
end

function maximums = localMaximums(config)
if ~isfield(config, "rangeSensitivity") || ...
        ~isstruct(config.rangeSensitivity) || ...
        ~isfield(config.rangeSensitivity, "maximumDeformations")
    error("mechanics:workflow:MissingTensileApplicationRangeSensitivityConfig", ...
        "Configure rangeSensitivity.maximumDeformations.");
end
maximums = reshape(double(config.rangeSensitivity.maximumDeformations), [], 1);
if isempty(maximums) || any(~isfinite(maximums)) || ...
        any(maximums <= config.fitRange(1)) || ...
        numel(unique(maximums)) ~= numel(maximums)
    error("mechanics:workflow:InvalidTensileApplicationRangeSensitivityMaximums", ...
        "Sensitivity maxima must be unique finite values above fitRange(1).");
end
maximums = sort(maximums);
end

function value = localMu0(properties)
match = properties.names == "mu0";
if nnz(match) ~= 1
    error("mechanics:models:MissingMu0ReferenceProperty", ...
        "The selected model must expose exactly one mu0 reference property.");
end
value = properties.values(match);
end
