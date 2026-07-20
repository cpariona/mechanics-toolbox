function stress = evaluateModel(modelName, deformation, parameters, context)
%EVALUATEMODEL Evaluate a registered hyperelastic model.
arguments
    modelName (1,1) string
    deformation {mustBeNumeric, mustBeReal}
    parameters {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
end

model = mechanics.models.modelRegistry(modelName);
expectedCount = numel(model.parameterNames);

if numel(parameters) ~= expectedCount
    error("mechanics:models:InvalidParameterCount", ...
        "Model '%s' requires %d parameters: %s.", ...
        model.name, expectedCount, strjoin(model.parameterNames, ", "));
end

stress = model.functionHandle(deformation, parameters, context);
end
