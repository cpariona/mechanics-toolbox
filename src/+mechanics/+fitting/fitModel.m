function fitResult = fitModel(modelName, deformation, measuredStress, context, config)
%FITMODEL Fit one registered hyperelastic model to uniaxial data.
arguments
    modelName (1,1) string
    deformation {mustBeNumeric, mustBeReal}
    measuredStress {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
    config (1,1) struct = mechanics.config.fittingConfig()
end

if numel(deformation) ~= numel(measuredStress)
    error("mechanics:fitting:SizeMismatch", ...
        "Deformation and stress must contain the same number of values.");
end

model = mechanics.models.modelRegistry(modelName);
config = mechanics.fitting.resolveFitConfig(config, model, numel(measuredStress));
[x, y, weights] = mechanics.fitting.prepareFitData(deformation, measuredStress, config);
if numel(y) <= numel(model.parameterNames)
    error("mechanics:fitting:InsufficientData", ...
        "The number of valid observations must exceed the number of fitted parameters.");
end

rng(config.randomSeed, "twister");
starts = mechanics.fitting.generateInitialGuesses( ...
    config.initialGuess, config.lowerBounds, config.upperBounds, config.numberOfStarts);

bestObjective = Inf;
bestParameters = [];
bestExitFlag = NaN;
bestOutput = struct();
allStarts = repmat(struct("initialGuess", [], "parameters", [], ...
    "objective", Inf, "exitFlag", NaN, "output", struct()), size(starts,1), 1);

options = optimset( ...
    "Display", char(config.display), ...
    "MaxIter", config.maxIterations, ...
    "MaxFunEvals", config.maxFunctionEvaluations, ...
    "TolFun", config.functionTolerance, ...
    "TolX", config.parameterTolerance);

for i = 1:size(starts,1)
    p0 = starts(i,:);
    z0 = mechanics.fitting.parametersToUnconstrained( ...
        p0, config.lowerBounds, config.upperBounds);

    objective = @(z) localObjective(z, model.name, x, y, weights, ...
        context, config.lowerBounds, config.upperBounds);

    [z, objectiveValue, exitFlag, output] = fminsearch(objective, z0, options);
    parameters = mechanics.fitting.unconstrainedToParameters( ...
        z, config.lowerBounds, config.upperBounds);

    allStarts(i).initialGuess = p0;
    allStarts(i).parameters = parameters;
    allStarts(i).objective = objectiveValue;
    allStarts(i).exitFlag = exitFlag;
    allStarts(i).output = output;

    if isfinite(objectiveValue) && objectiveValue < bestObjective
        bestObjective = objectiveValue;
        bestParameters = parameters;
        bestExitFlag = exitFlag;
        bestOutput = output;
    end
end

if isempty(bestParameters)
    error("mechanics:fitting:NoValidSolution", ...
        "No finite fitting solution was found for model '%s'.", model.name);
end

predictedStress = mechanics.models.evaluateModel( ...
    model.name, x, bestParameters, context);
residuals = y - predictedStress;
metrics = mechanics.fitting.computeFitMetrics(y, predictedStress, numel(bestParameters));

fitResult.modelName = model.name;
fitResult.parameterNames = model.parameterNames;
fitResult.parameters = bestParameters;
fitResult.deformation = x;
fitResult.measuredStress = y;
fitResult.predictedStress = predictedStress;
fitResult.residuals = residuals;
fitResult.metrics = metrics;
fitResult.objective = bestObjective;
fitResult.exitFlag = bestExitFlag;
fitResult.output = bestOutput;
fitResult.converged = bestExitFlag > 0;
fitResult.context = context;
fitResult.config = config;
fitResult.starts = allStarts;
end

function value = localObjective(z, modelName, x, y, weights, context, lowerBounds, upperBounds)
parameters = mechanics.fitting.unconstrainedToParameters(z, lowerBounds, upperBounds);
try
    prediction = mechanics.models.evaluateModel(modelName, x, parameters, context);
    residual = y - prediction;
    value = sum(weights .* residual.^2);
    if ~isfinite(value)
        value = realmax("double") / 100;
    end
catch
    value = realmax("double") / 100;
end
end
