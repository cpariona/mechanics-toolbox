function model = modelRegistry(modelName)
%MODELREGISTRY Return metadata and defaults for a hyperelastic model.
arguments
    modelName (1,1) string
end

normalizedName = lower(strrep(strrep(strtrim(modelName), "_", "-"), " ", "-"));

switch normalizedName
    case {"neo-hookean", "neohookean"}
        model.name = "neo-hookean";
        model.functionHandle = @mechanics.models.neoHookean;
        model.parameterNames = "mu";
        model.defaultInitialGuess = 1;
        model.lowerBounds = 0;
        model.upperBounds = Inf;
        model.description = "Incompressible one-parameter Neo-Hookean model.";

    case {"mooney-rivlin", "mooneyrivlin"}
        model.name = "mooney-rivlin";
        model.functionHandle = @mechanics.models.mooneyRivlin;
        model.parameterNames = ["C10", "C01"];
        model.defaultInitialGuess = [0.5, 0.5];
        model.lowerBounds = [0, 0];
        model.upperBounds = [Inf, Inf];
        model.description = "Incompressible two-parameter Mooney-Rivlin model.";

    case "yeoh"
        model.name = "yeoh";
        model.functionHandle = @mechanics.models.yeoh;
        model.parameterNames = ["C10", "C20", "C30"];
        model.defaultInitialGuess = [1, 0, 0];
        model.lowerBounds = [0, -Inf, -Inf];
        model.upperBounds = [Inf, Inf, Inf];
        model.description = "Incompressible third-order Yeoh model.";

    otherwise
        error("mechanics:models:UnknownModel", ...
            "Unknown hyperelastic model: %s", modelName);
end
end
