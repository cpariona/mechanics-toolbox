function validateParameters(parameters, expectedCount, modelName)
%VALIDATEPARAMETERS Validate a numerical model parameter vector.
arguments
    parameters {mustBeNumeric, mustBeReal}
    expectedCount (1,1) double {mustBeInteger, mustBePositive}
    modelName (1,1) string
end

if numel(parameters) ~= expectedCount
    error("mechanics:models:InvalidParameterCount", ...
        "Model '%s' requires %d parameters.", modelName, expectedCount);
end

if any(~isfinite(parameters(:)))
    error("mechanics:models:InvalidParameters", ...
        "Parameters for model '%s' must be finite.", modelName);
end
end
