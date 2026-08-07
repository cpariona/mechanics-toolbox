function model = modelRegistry(modelName)
%MODELREGISTRY Return metadata and defaults for a hyperelastic model.
arguments
    modelName (1,1) string
end

normalizedName = lower(strrep(strrep(strtrim(modelName), "_", "-"), " ", "-"));

switch normalizedName
    case {"neo-hookean", "neohookean"}
        model.name = "neo-hookean";
        model.displayName = "Neo-Hookean";
        model.familyName = "neo-hookean";
        model.order = NaN;
        model.functionHandle = @mechanics.models.neoHookean;
        model.parameterNames = "mu";
        model.defaultInitialGuess = 1;
        model.lowerBounds = 0;
        model.upperBounds = Inf;
        model.description = "Incompressible one-parameter Neo-Hookean model.";
        model.derivedQuantityNames = "mu0";
        model.evaluateDerivedQuantities = @(parameters) parameters(1);

    case {"mooney-rivlin", "mooneyrivlin"}
        model.name = "mooney-rivlin";
        model.displayName = "Mooney-Rivlin";
        model.familyName = "mooney-rivlin";
        model.order = NaN;
        model.functionHandle = @mechanics.models.mooneyRivlin;
        model.parameterNames = ["C10", "C01"];
        model.defaultInitialGuess = [0.5, 0.5];
        model.lowerBounds = [0, 0];
        model.upperBounds = [Inf, Inf];
        model.description = "Incompressible two-parameter Mooney-Rivlin model.";
        model.derivedQuantityNames = "mu0";
        model.evaluateDerivedQuantities = ...
            @(parameters) 2 * (parameters(1) + parameters(2));

    case "yeoh-second-order"
        model.name = "yeoh-second-order";
        model.displayName = "Yeoh second order";
        model.familyName = "yeoh";
        model.order = 2;
        model.functionHandle = @mechanics.models.yeoh;
        model.parameterNames = ["C10", "C20"];
        model.defaultInitialGuess = [1, 0];
        model.lowerBounds = [0, -Inf];
        model.upperBounds = [Inf, Inf];
        model.description = "Incompressible second-order Yeoh model.";
        model.derivedQuantityNames = "mu0";
        model.evaluateDerivedQuantities = @(parameters) 2 * parameters(1);

    case "yeoh-third-order"
        model.name = "yeoh-third-order";
        model.displayName = "Yeoh third order";
        model.familyName = "yeoh";
        model.order = 3;
        model.functionHandle = @mechanics.models.yeoh;
        model.parameterNames = ["C10", "C20", "C30"];
        model.defaultInitialGuess = [1, 0, 0];
        model.lowerBounds = [0, -Inf, -Inf];
        model.upperBounds = [Inf, Inf, Inf];
        model.description = "Incompressible third-order Yeoh model.";
        model.derivedQuantityNames = "mu0";
        model.evaluateDerivedQuantities = @(parameters) 2 * parameters(1);

    otherwise
        error("mechanics:models:UnknownModel", ...
            "Unknown hyperelastic model: %s", modelName);
end
end
