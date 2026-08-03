function fitResult = fitTensileApplicationRangeModel(normalized, modelName, config)
%FITTENSILEAPPLICATIONRANGEMODEL Fit one model across range-limited tensile specimens.
arguments
    normalized (1,1) struct
    modelName (1,1) string
    config (1,1) struct = ...
        mechanics.config.tensileApplicationRangeCharacterizationConfig()
end

localValidateNormalized(normalized);
localValidateConfig(config);
model = mechanics.models.modelRegistry(modelName);
fitConfig = mechanics.fitting.resolveFitConfig( ...
    config.fitting, model, normalized.observationCount);
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
        unconstrained, model.name, normalized.specimens, normalization.scale, ...
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
    error("mechanics:fitting:NoValidTensileApplicationRangeSolution", ...
        "No finite application-range solution was found for model '%s'.", ...
        model.name);
end

[specimenFits, specimenSummary] = localDiagnostics( ...
    model.name, bestParameters, normalized.specimens, normalization.scale);

fitResult.modelName = model.name;
fitResult.parameterNames = model.parameterNames;
fitResult.parameters = bestParameters;
fitResult.objective = bestObjective;
fitResult.exitFlag = bestExitFlag;
fitResult.output = bestOutput;
fitResult.converged = bestExitFlag > 0;
fitResult.specimenWeighting = "equal";
fitResult.specimens = specimenFits;
fitResult.specimenSummary = specimenSummary;
fitResult.normalization = normalization;
fitResult.config = config;
fitResult.fitConfig = fitConfig;
fitResult.starts = allStarts;
fitResult.createdAt = datetime("now");
end

function value = localObjective(unconstrained, modelName, specimens, scales, ...
        lowerBounds, upperBounds)
parameters = mechanics.fitting.unconstrainedToParameters( ...
    unconstrained, lowerBounds, upperBounds);
try
    specimenLoss = zeros(numel(specimens), 1);
    for specimenIndex = 1:numel(specimens)
        specimen = specimens(specimenIndex);
        prediction = mechanics.models.evaluateModel( ...
            modelName, specimen.Deformation, parameters, specimen.Context);
        residual = specimen.MeasuredStress - prediction;
        specimenLoss(specimenIndex) = mean( ...
            (residual ./ scales(specimenIndex)).^2);
    end
    value = mean(specimenLoss);
    if ~isfinite(value)
        value = realmax("double") / 100;
    end
catch
    value = realmax("double") / 100;
end
end

function [specimenFits, specimenSummary] = localDiagnostics( ...
        modelName, parameters, specimens, scales)
specimenCount = numel(specimens);
specimenFits = specimens;
sourceRecordIndex = zeros(specimenCount, 1);
sourceSpecimenId = strings(specimenCount, 1);
observationCount = zeros(specimenCount, 1);
normalizationScale = zeros(specimenCount, 1);
rmse = zeros(specimenCount, 1);
normalizedRMSE = zeros(specimenCount, 1);
maximumAbsoluteError = zeros(specimenCount, 1);
normalizedLoss = zeros(specimenCount, 1);

for specimenIndex = 1:specimenCount
    specimen = specimens(specimenIndex);
    prediction = mechanics.models.evaluateModel( ...
        modelName, specimen.Deformation, parameters, specimen.Context);
    residual = specimen.MeasuredStress - prediction;
    specimenFits(specimenIndex).PredictedStress = prediction;
    specimenFits(specimenIndex).Residuals = residual;
    specimenFits(specimenIndex).NormalizationScale = scales(specimenIndex);

    sourceRecordIndex(specimenIndex) = specimen.SourceRecordIndex;
    sourceSpecimenId(specimenIndex) = specimen.SourceSpecimenId;
    observationCount(specimenIndex) = specimen.ObservationCount;
    normalizationScale(specimenIndex) = scales(specimenIndex);
    rmse(specimenIndex) = sqrt(mean(residual.^2));
    normalizedRMSE(specimenIndex) = rmse(specimenIndex) ./ scales(specimenIndex);
    maximumAbsoluteError(specimenIndex) = max(abs(residual));
    normalizedLoss(specimenIndex) = mean( ...
        (residual ./ scales(specimenIndex)).^2);
end

specimenSummary = table(sourceRecordIndex, sourceSpecimenId, ...
    observationCount, normalizationScale, rmse, normalizedRMSE, ...
    maximumAbsoluteError, normalizedLoss, ...
    'VariableNames', {'SourceRecordIndex','SourceSpecimenId', ...
    'ObservationCount','NormalizationScale','RMSE','NormalizedRMSE', ...
    'MaximumAbsoluteError','NormalizedLoss'});
end

function normalization = localNormalization(specimens, config)
if ~isstruct(config) || ~all(isfield(config, ["method","minimumScale"]))
    error("mechanics:fitting:InvalidTensileApplicationRangeNormalization", ...
        "normalization must define method and minimumScale.");
end
method = lower(strtrim(string(config.method)));
if ~isscalar(method) || method ~= "response-range"
    error("mechanics:fitting:UnknownTensileApplicationRangeNormalization", ...
        "Unsupported application-range normalization method: %s", method);
end
minimumScale = double(config.minimumScale);
if ~isscalar(minimumScale) || ~isfinite(minimumScale) || minimumScale <= 0
    error("mechanics:fitting:InvalidTensileApplicationRangeNormalization", ...
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

function localValidateConfig(config)
if ~isfield(config, "specimenWeighting") || ...
        lower(strtrim(string(config.specimenWeighting))) ~= "equal"
    error("mechanics:fitting:UnsupportedTensileApplicationRangeWeighting", ...
        "Application-range fitting requires equal specimen weighting.");
end
if ~isfield(config, "normalization") || ~isfield(config, "fitting")
    error("mechanics:fitting:InvalidTensileApplicationRangeFitConfig", ...
        "Application-range configuration must define normalization and fitting.");
end
end

function localValidateNormalized(normalized)
required = ["specimens", "specimenCount", "observationCount"];
if ~all(isfield(normalized, required)) || normalized.specimenCount < 1 || ...
        normalized.observationCount < 1 || isempty(normalized.specimens) || ...
        normalized.specimenCount ~= numel(normalized.specimens)
    error("mechanics:fitting:InvalidNormalizedTensileApplicationRangeData", ...
        "Provide a nonempty normalized tensile application-range result.");
end
end
