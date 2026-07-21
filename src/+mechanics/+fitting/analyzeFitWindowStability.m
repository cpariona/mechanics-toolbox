function stability = analyzeFitWindowStability( ...
        modelName, deformation, measuredStress, context, fitConfig, config)
%ANALYZEFITWINDOWSTABILITY Fit one model over nested deformation windows.
arguments
    modelName (1,1) string
    deformation {mustBeNumeric, mustBeReal}
    measuredStress {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
    fitConfig (1,1) struct = mechanics.config.fittingConfig()
    config (1,1) struct = mechanics.config.fitWindowStabilityConfig()
end

x = deformation(:);
y = measuredStress(:);
if numel(x) ~= numel(y)
    error("mechanics:fitting:WindowStabilitySizeMismatch", ...
        "Deformation and stress must have equal lengths.");
end

valid = isfinite(x) & isfinite(y);
x = x(valid);
y = y(valid);
if numel(x) < config.minimumObservations
    error("mechanics:fitting:InsufficientWindowStabilityData", ...
        "At least %d finite observations are required.", ...
        config.minimumObservations);
end

[x, order] = sort(x, "ascend");
y = y(order);
windowFractions = unique(config.windowFractions(:), "stable");
if isempty(windowFractions) || any(~isfinite(windowFractions)) || ...
        any(windowFractions <= 0 | windowFractions > 1)
    error("mechanics:fitting:InvalidWindowFractions", ...
        "windowFractions must contain finite values in (0, 1].");
end

model = mechanics.models.modelRegistry(modelName);
parameterCount = numel(model.parameterNames);
windowCount = numel(windowFractions);
parameterMatrix = nan(windowCount, parameterCount);
rmse = nan(windowCount, 1);
rSquared = nan(windowCount, 1);
observationCount = zeros(windowCount, 1);
maximumDeformation = nan(windowCount, 1);
success = false(windowCount, 1);
errorIdentifier = strings(windowCount, 1);
errorMessage = strings(windowCount, 1);
fitResults = cell(windowCount, 1);

xMinimum = min(x);
xMaximum = max(x);
span = xMaximum - xMinimum;
if span <= 0
    error("mechanics:fitting:InvalidWindowStabilityRange", ...
        "Deformation must span a nonzero range.");
end

for index = 1:windowCount
    limit = xMinimum + windowFractions(index) * span;
    mask = x <= limit;
    observationCount(index) = nnz(mask);
    maximumDeformation(index) = max(x(mask));

    if observationCount(index) < config.minimumObservations
        errorIdentifier(index) = ...
            "mechanics:fitting:InsufficientWindowObservations";
        errorMessage(index) = sprintf( ...
            "Window contains %d observations; %d are required.", ...
            observationCount(index), config.minimumObservations);
        continue;
    end

    try
        result = mechanics.fitting.fitModel( ...
            modelName, x(mask), y(mask), context, fitConfig);
        fitResults{index} = result;
        parameterMatrix(index, :) = result.parameters;
        rmse(index) = result.metrics.rmse;
        rSquared(index) = result.metrics.rSquared;
        success(index) = true;
    catch ME
        errorIdentifier(index) = string(ME.identifier);
        errorMessage(index) = string(ME.message);
        if ~config.continueOnFitError
            rethrow(ME);
        end
    end
end

successfulCount = nnz(success);
if successfulCount < config.minimumSuccessfulWindows
    error("mechanics:fitting:InsufficientSuccessfulWindows", ...
        "Only %d windows succeeded; %d are required.", ...
        successfulCount, config.minimumSuccessfulWindows);
end

validParameters = parameterMatrix(success, :);
parameterMinimum = min(validParameters, [], 1)';
parameterMaximum = max(validParameters, [], 1)';
parameterRange = parameterMaximum - parameterMinimum;

switch lower(string(config.referenceMode))
    case "full-window"
        referenceIndex = find(success, 1, "last");
        referenceParameters = parameterMatrix(referenceIndex, :)';
    case "median"
        referenceIndex = NaN;
        referenceParameters = median(validParameters, 1)';
    otherwise
        error("mechanics:fitting:UnknownWindowReferenceMode", ...
            "Unknown reference mode: %s", config.referenceMode);
end

relativeParameterRange = parameterRange ./ ...
    max(abs(referenceParameters), config.normalizationFloor);
unstableParameter = relativeParameterRange > ...
    config.relativeParameterRangeThreshold;

windowSummary = table(windowFractions, maximumDeformation, ...
    observationCount, success, rmse, rSquared, ...
    errorIdentifier, errorMessage, ...
    'VariableNames', {'WindowFraction','MaximumDeformation', ...
    'ObservationCount','Success','RMSE','RSquared', ...
    'ErrorIdentifier','ErrorMessage'});

parameterSummary = table(string(model.parameterNames(:)), ...
    referenceParameters, parameterMinimum, parameterMaximum, ...
    parameterRange, relativeParameterRange, unstableParameter, ...
    'VariableNames', {'Parameter','ReferenceValue','MinimumValue', ...
    'MaximumValue','AbsoluteRange','RelativeRange','Unstable'});

stability.modelName = model.name;
stability.parameterNames = string(model.parameterNames(:));
stability.windowFractions = windowFractions;
stability.parameterMatrix = parameterMatrix;
stability.windowSummary = windowSummary;
stability.parameterSummary = parameterSummary;
stability.successMask = success;
stability.successfulWindowCount = successfulCount;
stability.referenceIndex = referenceIndex;
stability.referenceParameters = referenceParameters;
stability.hasUnstableParameter = any(unstableParameter);
stability.stable = ~stability.hasUnstableParameter;
stability.fitResults = fitResults;
stability.context = context;
stability.fitConfig = fitConfig;
stability.config = config;
end
