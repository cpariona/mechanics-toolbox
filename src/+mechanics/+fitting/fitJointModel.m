function fitResult = fitJointModel(normalized, modelName, config)
%FITJOINTMODEL Fit one registered model across normalized experimental modes.
arguments
    normalized (1,1) struct
    modelName (1,1) string
    config (1,1) struct = mechanics.config.jointMaterialCharacterizationConfig()
end

localValidateNormalized(normalized);
model = mechanics.models.modelRegistry(modelName);
fitConfig = mechanics.fitting.resolveFitConfig( ...
    config.fitting, model, normalized.observationCount);
modeWeights = localModeWeights(normalized.modeNames, config);
normalization = localNormalization(normalized.specimens, config.normalization);

rng(fitConfig.randomSeed, "twister");
starts = mechanics.fitting.generateInitialGuesses( ...
    fitConfig.initialGuess, fitConfig.lowerBounds, ...
    fitConfig.upperBounds, fitConfig.numberOfStarts);
options = optimset( ...
    "Display", char(fitConfig.display), ...
    "MaxIter", fitConfig.maxIterations, ...
    "MaxFunEvals", fitConfig.maxFunctionEvaluations, ...
    "TolFun", fitConfig.functionTolerance, ...
    "TolX", fitConfig.parameterTolerance);

bestObjective = Inf;
bestParameters = [];
bestExitFlag = NaN;
bestOutput = struct();
allStarts = repmat(struct("initialGuess", [], "parameters", [], ...
    "objective", Inf, "exitFlag", NaN, "output", struct()), ...
    size(starts, 1), 1);

for startIndex = 1:size(starts, 1)
    initialGuess = starts(startIndex, :);
    unconstrainedInitial = mechanics.fitting.parametersToUnconstrained( ...
        initialGuess, fitConfig.lowerBounds, fitConfig.upperBounds);
    objective = @(unconstrained) localObjective( ...
        unconstrained, model.name, normalized, normalization, modeWeights, ...
        fitConfig.lowerBounds, fitConfig.upperBounds);
    [unconstrained, objectiveValue, exitFlag, output] = ...
        fminsearch(objective, unconstrainedInitial, options);
    parameters = mechanics.fitting.unconstrainedToParameters( ...
        unconstrained, fitConfig.lowerBounds, fitConfig.upperBounds);

    allStarts(startIndex).initialGuess = initialGuess;
    allStarts(startIndex).parameters = parameters;
    allStarts(startIndex).objective = objectiveValue;
    allStarts(startIndex).exitFlag = exitFlag;
    allStarts(startIndex).output = output;

    if isfinite(objectiveValue) && objectiveValue < bestObjective
        bestObjective = objectiveValue;
        bestParameters = parameters;
        bestExitFlag = exitFlag;
        bestOutput = output;
    end
end

if isempty(bestParameters)
    error("mechanics:fitting:NoValidJointSolution", ...
        "No finite joint fitting solution was found for model '%s'.", model.name);
end

[specimenFits, specimenSummary, modeSummary] = localDiagnostics( ...
    model.name, bestParameters, normalized, normalization, modeWeights);

fitResult.modelName = model.name;
fitResult.parameterNames = model.parameterNames;
fitResult.parameters = bestParameters;
fitResult.objective = bestObjective;
fitResult.exitFlag = bestExitFlag;
fitResult.output = bestOutput;
fitResult.converged = bestExitFlag > 0;
fitResult.modeNames = normalized.modeNames;
fitResult.modeWeights = modeWeights;
fitResult.specimens = specimenFits;
fitResult.specimenSummary = specimenSummary;
fitResult.modeSummary = modeSummary;
fitResult.normalization = normalization;
fitResult.config = config;
fitResult.fitConfig = fitConfig;
fitResult.starts = allStarts;
fitResult.createdAt = datetime("now");
end

function value = localObjective(unconstrained, modelName, normalized, ...
        normalization, modeWeights, lowerBounds, upperBounds)
parameters = mechanics.fitting.unconstrainedToParameters( ...
    unconstrained, lowerBounds, upperBounds);
try
    modeLoss = zeros(numel(normalized.modeNames), 1);
    specimenModes = string({normalized.specimens.Mode})';
    for modeIndex = 1:numel(normalized.modeNames)
        specimenIndices = find(specimenModes == normalized.modeNames(modeIndex));
        specimenLoss = zeros(numel(specimenIndices), 1);
        for localIndex = 1:numel(specimenIndices)
            specimenIndex = specimenIndices(localIndex);
            specimen = normalized.specimens(specimenIndex);
            prediction = mechanics.models.evaluateModel( ...
                modelName, specimen.Deformation, parameters, specimen.Context);
            residual = specimen.MeasuredStress - prediction;
            specimenLoss(localIndex) = mean( ...
                (residual ./ normalization.scale(specimenIndex)).^2);
        end
        modeLoss(modeIndex) = mean(specimenLoss);
    end
    value = sum(modeWeights .* modeLoss);
    if ~isfinite(value)
        value = realmax("double") / 100;
    end
catch
    value = realmax("double") / 100;
end
end

function [specimenFits, specimenSummary, modeSummary] = localDiagnostics( ...
        modelName, parameters, normalized, normalization, modeWeights)
specimenCount = numel(normalized.specimens);
specimenFits = normalized.specimens;
mode = strings(specimenCount, 1);
specimenId = strings(specimenCount, 1);
observationCount = zeros(specimenCount, 1);
scale = zeros(specimenCount, 1);
rmse = zeros(specimenCount, 1);
normalizedRMSE = zeros(specimenCount, 1);
maximumAbsoluteError = zeros(specimenCount, 1);

for specimenIndex = 1:specimenCount
    specimen = normalized.specimens(specimenIndex);
    prediction = mechanics.models.evaluateModel( ...
        modelName, specimen.Deformation, parameters, specimen.Context);
    residual = specimen.MeasuredStress - prediction;
    specimenFits(specimenIndex).PredictedStress = prediction;
    specimenFits(specimenIndex).Residuals = residual;
    specimenFits(specimenIndex).NormalizationScale = ...
        normalization.scale(specimenIndex);

    mode(specimenIndex) = specimen.Mode;
    specimenId(specimenIndex) = specimen.SpecimenId;
    observationCount(specimenIndex) = specimen.ObservationCount;
    scale(specimenIndex) = normalization.scale(specimenIndex);
    rmse(specimenIndex) = sqrt(mean(residual.^2));
    normalizedRMSE(specimenIndex) = rmse(specimenIndex) ./ scale(specimenIndex);
    maximumAbsoluteError(specimenIndex) = max(abs(residual));
end

specimenSummary = table(mode, specimenId, observationCount, scale, rmse, ...
    normalizedRMSE, maximumAbsoluteError, ...
    'VariableNames', {'Mode','SpecimenId','ObservationCount', ...
    'NormalizationScale','RMSE','NormalizedRMSE','MaximumAbsoluteError'});

modeCount = numel(normalized.modeNames);
modeName = normalized.modeNames;
weight = modeWeights;
modeSpecimenCount = zeros(modeCount, 1);
meanRMSE = zeros(modeCount, 1);
meanNormalizedRMSE = zeros(modeCount, 1);
normalizedLoss = zeros(modeCount, 1);
for modeIndex = 1:modeCount
    mask = mode == modeName(modeIndex);
    modeSpecimenCount(modeIndex) = nnz(mask);
    meanRMSE(modeIndex) = mean(rmse(mask));
    meanNormalizedRMSE(modeIndex) = mean(normalizedRMSE(mask));
    normalizedLoss(modeIndex) = mean(normalizedRMSE(mask).^2);
end
modeSummary = table(modeName, weight, modeSpecimenCount, meanRMSE, ...
    meanNormalizedRMSE, normalizedLoss, ...
    'VariableNames', {'Mode','Weight','SpecimenCount','MeanRMSE', ...
    'MeanNormalizedRMSE','NormalizedLoss'});
end

function normalization = localNormalization(specimens, config)
method = lower(string(config.method));
if method ~= "response-range"
    error("mechanics:fitting:UnknownJointNormalization", ...
        "Unsupported joint normalization method: %s", method);
end
minimumScale = double(config.minimumScale);
if ~isscalar(minimumScale) || ~isfinite(minimumScale) || minimumScale <= 0
    error("mechanics:fitting:InvalidJointNormalizationScale", ...
        "normalization.minimumScale must be finite and positive.");
end
scale = zeros(numel(specimens), 1);
for specimenIndex = 1:numel(specimens)
    response = specimens(specimenIndex).MeasuredStress;
    responseScale = max(response) - min(response);
    if ~isfinite(responseScale) || responseScale < minimumScale
        responseScale = max(abs(response));
    end
    scale(specimenIndex) = max(responseScale, minimumScale);
end
normalization.method = method;
normalization.minimumScale = minimumScale;
normalization.scale = scale;
end

function weights = localModeWeights(modeNames, config)
configuredNames = lower(strtrim(string(config.modeNames(:))));
configuredWeights = reshape(double(config.modeWeights), [], 1);
if numel(configuredNames) ~= numel(configuredWeights) || ...
        numel(unique(configuredNames)) ~= numel(configuredNames) || ...
        any(~isfinite(configuredWeights)) || any(configuredWeights <= 0)
    error("mechanics:fitting:InvalidJointModeWeights", ...
        "Configure one unique finite positive weight per mode.");
end
weights = zeros(numel(modeNames), 1);
for modeIndex = 1:numel(modeNames)
    match = configuredNames == lower(string(modeNames(modeIndex)));
    if nnz(match) ~= 1
        error("mechanics:fitting:InvalidJointModeWeights", ...
            "No unique configured weight exists for mode %s.", modeNames(modeIndex));
    end
    weights(modeIndex) = configuredWeights(match);
end
weights = weights ./ sum(weights);
end

function localValidateNormalized(normalized)
required = ["modeNames", "specimens", "specimenCount", "observationCount"];
if ~all(isfield(normalized, required)) || normalized.specimenCount < 1 || ...
        normalized.observationCount < 1 || isempty(normalized.specimens)
    error("mechanics:fitting:InvalidNormalizedJointData", ...
        "Provide a nonempty result from normalizeJointCharacterizationStudies.");
end
end
