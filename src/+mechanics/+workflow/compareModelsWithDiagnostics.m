function comparison = compareModelsWithDiagnostics( ...
        modelNames, deformation, measuredStress, context, fitConfig, config)
%COMPAREMODELSWITHDIAGNOSTICS Compare models using fit and reliability evidence.
arguments
    modelNames {mustBeText}
    deformation {mustBeNumeric, mustBeReal}
    measuredStress {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
    fitConfig (1,1) struct = mechanics.config.fittingConfig()
    config (1,1) struct = mechanics.config.modelComparisonWorkflowConfig()
end

modelNames = string(modelNames(:));
if isempty(modelNames)
    error("mechanics:workflow:EmptyModelComparison", ...
        "At least one model name is required.");
end

modelCount = numel(modelNames);
analyses = cell(modelCount, 1);
success = false(modelCount, 1);
eligible = false(modelCount, 1);
reliabilityStatus = strings(modelCount, 1);
rmse = nan(modelCount, 1);
normalizedRmse = nan(modelCount, 1);
rSquared = nan(modelCount, 1);
parameterCount = nan(modelCount, 1);
aic = nan(modelCount, 1);
aicc = nan(modelCount, 1);
bic = nan(modelCount, 1);
errorIdentifier = strings(modelCount, 1);
errorMessage = strings(modelCount, 1);

for index = 1:modelCount
    try
        analysis = mechanics.workflow.runFitDiagnostics( ...
            modelNames(index), deformation, measuredStress, context, ...
            fitConfig, config.fitDiagnosticsConfig);
        analyses{index} = analysis;
        success(index) = true;
        reliabilityStatus(index) = string(analysis.reliability.status);
        eligible(index) = any(reliabilityStatus(index) == ...
            string(config.allowedReliabilityStatuses(:)));

        residuals = analysis.fitResult.residuals(:);
        residuals = residuals(isfinite(residuals));
        observationCount = numel(residuals);
        parameterCount(index) = numel(analysis.fitResult.parameters);
        rss = sum(residuals .^ 2);
        rssFloor = max(rss, eps);
        aic(index) = observationCount * log(rssFloor / observationCount) + ...
            2 * parameterCount(index);
        denominator = observationCount - parameterCount(index) - 1;
        if denominator > 0
            aicc(index) = aic(index) + ...
                (2 * parameterCount(index) * (parameterCount(index) + 1)) / ...
                denominator;
        end
        bic(index) = observationCount * log(rssFloor / observationCount) + ...
            parameterCount(index) * log(observationCount);

        metrics = analysis.fitResult.metrics;
        rmse(index) = metrics.rmse;
        normalizedRmse(index) = metrics.normalizedRmse;
        rSquared(index) = metrics.rSquared;
    catch ME
        errorIdentifier(index) = string(ME.identifier);
        errorMessage(index) = string(ME.message);
        if ~config.continueOnModelError
            rethrow(ME);
        end
    end
end

criterion = lower(string(config.selectionCriterion));
switch criterion
    case "aicc"
        criterionValue = aicc;
    case "aic"
        criterionValue = aic;
    case "bic"
        criterionValue = bic;
    case "rmse"
        criterionValue = rmse;
    case "normalized-rmse"
        criterionValue = normalizedRmse;
    otherwise
        error("mechanics:workflow:UnknownModelSelectionCriterion", ...
            "Unknown model-selection criterion: %s", config.selectionCriterion);
end

candidate = success & eligible & isfinite(criterionValue);
selectedIndex = NaN;
selectedModelName = "";
if any(candidate)
    candidateIndices = find(candidate);
    [~, localIndex] = min(criterionValue(candidate));
    selectedIndex = candidateIndices(localIndex);
    selectedModelName = modelNames(selectedIndex);
elseif config.requireEligibleModel
    error("mechanics:workflow:NoEligibleConstitutiveModel", ...
        "No successfully fitted model satisfied the reliability requirements.");
end

rank = nan(modelCount, 1);
if any(candidate)
    candidateIndices = find(candidate);
    [~, order] = sort(criterionValue(candidate), "ascend");
    rank(candidateIndices(order)) = (1:numel(candidateIndices))';
end

summary = table(modelNames, success, reliabilityStatus, eligible, ...
    parameterCount, rmse, normalizedRmse, rSquared, aic, aicc, bic, ...
    criterionValue, rank, errorIdentifier, errorMessage, ...
    'VariableNames', {'ModelName','Success','ReliabilityStatus','Eligible', ...
    'ParameterCount','RMSE','NormalizedRMSE','RSquared','AIC','AICc','BIC', ...
    'CriterionValue','Rank','ErrorIdentifier','ErrorMessage'});

comparison.modelNames = modelNames;
comparison.createdAt = datetime("now");
comparison.selectionCriterion = criterion;
comparison.allowedReliabilityStatuses = ...
    string(config.allowedReliabilityStatuses(:));
comparison.selectedIndex = selectedIndex;
comparison.selectedModelName = selectedModelName;
comparison.hasSelectedModel = isfinite(selectedIndex);
comparison.summary = summary;
comparison.analyses = analyses;
comparison.context = context;
comparison.fitConfig = fitConfig;
comparison.config = config;
end
