function candidates = fitTensileApplicationRangeModels(normalized, config)
%FITTENSILEAPPLICATIONRANGEMODELS Fit every configured candidate model.
arguments
    normalized (1,1) struct
    config (1,1) struct = ...
        mechanics.config.tensileApplicationRangeCharacterizationConfig()
end

if ~isfield(config, "candidateModelNames")
    error("mechanics:workflow:MissingTensileApplicationRangeCandidates", ...
        "Application-range configuration must define candidateModelNames.");
end
modelNames = string(config.candidateModelNames(:));
if isempty(modelNames)
    error("mechanics:workflow:MissingTensileApplicationRangeCandidates", ...
        "Configure at least one candidate model.");
end

candidates = repmat(localEmptyCandidate(), numel(modelNames), 1);
for index = 1:numel(modelNames)
    candidates(index).modelName = modelNames(index);
    try
        fit = mechanics.fitting.fitTensileApplicationRangeModel( ...
            normalized, modelNames(index), config);
        candidates(index).status = "completed";
        candidates(index).fit = fit;
        candidates(index).objective = fit.objective;
        candidates(index).converged = fit.converged;
        candidates(index).parameterCount = numel(fit.parameters);
    catch exception
        candidates(index).status = "failed";
        candidates(index).errorIdentifier = string(exception.identifier);
        candidates(index).errorMessage = string(exception.message);
    end
end
end

function item = localEmptyCandidate()
item.modelName = "";
item.status = "pending";
item.fit = struct();
item.objective = Inf;
item.converged = false;
item.parameterCount = 0;
item.errorIdentifier = "";
item.errorMessage = "";
end
