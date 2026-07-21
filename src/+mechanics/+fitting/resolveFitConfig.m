function config = resolveFitConfig(config, model, observationCount)
%RESOLVEFITCONFIG Fill missing settings and validate fitting configuration.
defaults = mechanics.config.fittingConfig();
fields = fieldnames(defaults);
for i = 1:numel(fields)
    name = fields{i};
    if ~isfield(config, name) || isempty(config.(name))
        config.(name) = defaults.(name);
    end
end

if isempty(config.initialGuess)
    config.initialGuess = model.defaultInitialGuess;
end
if isempty(config.lowerBounds)
    config.lowerBounds = model.lowerBounds;
end
if isempty(config.upperBounds)
    config.upperBounds = model.upperBounds;
end

config.initialGuess = reshape(config.initialGuess, 1, []);
config.lowerBounds = reshape(config.lowerBounds, 1, []);
config.upperBounds = reshape(config.upperBounds, 1, []);
parameterCount = numel(model.parameterNames);

if any([numel(config.initialGuess), numel(config.lowerBounds), ...
        numel(config.upperBounds)] ~= parameterCount)
    error("mechanics:fitting:InvalidParameterConfiguration", ...
        "Initial guesses and bounds must match the %d parameters of model '%s'.", ...
        parameterCount, model.name);
end
if any(config.lowerBounds >= config.upperBounds)
    error("mechanics:fitting:InvalidBounds", ...
        "Every lower bound must be smaller than its upper bound.");
end
if config.numberOfStarts < 1 || fix(config.numberOfStarts) ~= config.numberOfStarts
    error("mechanics:fitting:InvalidStartCount", ...
        "numberOfStarts must be a positive integer.");
end
if observationCount <= parameterCount
    error("mechanics:fitting:InsufficientData", ...
        "The number of observations must exceed the number of fitted parameters.");
end

margin = sqrt(eps);
for j = 1:parameterCount
    lb = config.lowerBounds(j);
    ub = config.upperBounds(j);
    p = config.initialGuess(j);
    if isfinite(lb) && p <= lb
        p = lb + margin * max(1, abs(lb));
    end
    if isfinite(ub) && p >= ub
        p = ub - margin * max(1, abs(ub));
    end
    config.initialGuess(j) = p;
end
end
