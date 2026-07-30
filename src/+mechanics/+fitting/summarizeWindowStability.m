function summary = summarizeWindowStability(study)
%SUMMARIZEWINDOWSTABILITY Summarize fit quality and window sensitivity.
arguments
    study (1,1) struct
end

modelNames = study.modelNames(:);
selectionConfig = study.selectionConfig;
nModels = numel(modelNames);

model = strings(nModels,1);
windowCount = zeros(nModels,1);
successfulWindowCount = zeros(nModels,1);
convergedWindowCount = zeros(nModels,1);
fullWindowParameterCount = nan(nModels,1);
fullWindowRMSE = nan(nModels,1);
fullWindowRSquared = nan(nModels,1);
fullWindowAIC = nan(nModels,1);
fullWindowBIC = nan(nModels,1);
maximumRelativeParameterCV = nan(nModels,1);
dominantCVParameter = strings(nModels,1);
hasParameterSignChange = false(nModels,1);
maximumSharedDomainNormalizedRMSE = nan(nModels,1);
maximumSharedDomainNormalizedMaxError = nan(nModels,1);
eligible = false(nModels,1);

parameterMeans = cell(nModels,1);
parameterStd = cell(nModels,1);
parameterCV = cell(nModels,1);
parameterNames = cell(nModels,1);

for iModel = 1:nModels
    model(iModel) = modelNames(iModel);
    records = study.records([study.records.modelName] == modelNames(iModel));
    windowCount(iModel) = numel(records);

    successMask = [records.succeeded];
    successful = records(successMask);
    successfulWindowCount(iModel) = numel(successful);

    if isempty(successful)
        continue;
    end

    convergedMask = arrayfun(@(r) r.fitResult.converged, successful);
    convergedWindowCount(iModel) = nnz(convergedMask);

    fractions = [successful.windowFraction];
    [~, fullIndex] = max(fractions);
    fullResult = successful(fullIndex).fitResult;
    fullWindowParameterCount(iModel) = fullResult.metrics.parameterCount;
    fullWindowRMSE(iModel) = fullResult.metrics.rmse;
    fullWindowRSquared(iModel) = fullResult.metrics.rSquared;
    fullWindowAIC(iModel) = fullResult.metrics.aic;
    fullWindowBIC(iModel) = fullResult.metrics.bic;

    names = fullResult.parameterNames(:)';
    parameterNames{iModel} = names;
    fitResults = vertcat(successful.fitResult);
    parameterMatrix = vertcat(fitResults.parameters);

    means = mean(parameterMatrix, 1);
    standardDeviations = std(parameterMatrix, 0, 1);
    scales = max(abs(means), selectionConfig.relativeScaleFloor);
    cvs = standardDeviations ./ scales;

    parameterMeans{iModel} = means;
    parameterStd{iModel} = standardDeviations;
    parameterCV{iModel} = cvs;
    if all(isfinite(cvs))
        [maximumRelativeParameterCV(iModel), dominantIndex] = max(cvs);
        dominantCVParameter(iModel) = names(dominantIndex);
    end
    hasParameterSignChange(iModel) = any( ...
        min(parameterMatrix, [], 1) < 0 & max(parameterMatrix, [], 1) > 0);

    normalizedRMSE = nan(numel(successful), 1);
    normalizedMaxError = nan(numel(successful), 1);
    for iWindow = 1:numel(successful)
        windowResult = successful(iWindow).fitResult;
        fullPrediction = mechanics.models.evaluateModel( ...
            fullResult.modelName, windowResult.deformation, ...
            fullResult.parameters, fullResult.context);
        difference = windowResult.predictedStress - fullPrediction;
        stressScale = max(range(windowResult.measuredStress), ...
            selectionConfig.relativeScaleFloor);
        normalizedRMSE(iWindow) = sqrt(mean(difference.^2)) ./ stressScale;
        normalizedMaxError(iWindow) = max(abs(difference)) ./ stressScale;
    end
    maximumSharedDomainNormalizedRMSE(iModel) = max(normalizedRMSE);
    maximumSharedDomainNormalizedMaxError(iModel) = max(normalizedMaxError);

    hasAllWindows = successfulWindowCount(iModel) == windowCount(iModel);
    convergenceAccepted = ~selectionConfig.requireConvergence || ...
        convergedWindowCount(iModel) == successfulWindowCount(iModel);
    finiteFullResult = all(isfinite(fullResult.parameters)) && ...
        isfinite(fullWindowRMSE(iModel)) && isfinite(fullWindowBIC(iModel));
    finiteResponseSensitivity = ...
        isfinite(maximumSharedDomainNormalizedRMSE(iModel)) && ...
        isfinite(maximumSharedDomainNormalizedMaxError(iModel));

    eligible(iModel) = hasAllWindows && convergenceAccepted && ...
        finiteFullResult && finiteResponseSensitivity;
end

summary = table( ...
    model, windowCount, successfulWindowCount, convergedWindowCount, ...
    fullWindowParameterCount, fullWindowRMSE, fullWindowRSquared, ...
    fullWindowAIC, fullWindowBIC, maximumRelativeParameterCV, ...
    dominantCVParameter, hasParameterSignChange, ...
    maximumSharedDomainNormalizedRMSE, ...
    maximumSharedDomainNormalizedMaxError, eligible, parameterNames, ...
    parameterMeans, parameterStd, parameterCV, ...
    'VariableNames', { ...
        'Model', 'WindowCount', 'SuccessfulWindowCount', ...
        'ConvergedWindowCount', 'FullWindowParameterCount', ...
        'FullWindowRMSE', 'FullWindowRSquared', 'FullWindowAIC', ...
        'FullWindowBIC', 'MaximumRelativeParameterCV', ...
        'DominantCVParameter', 'HasParameterSignChange', ...
        'MaximumSharedDomainNormalizedRMSE', ...
        'MaximumSharedDomainNormalizedMaxError', 'Eligible', ...
        'ParameterNames', 'ParameterMeans', 'ParameterStd', 'ParameterCV'});
end
