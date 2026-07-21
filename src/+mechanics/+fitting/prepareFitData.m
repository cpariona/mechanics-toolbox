function [deformation, stress, weights] = prepareFitData(deformation, stress, config)
%PREPAREFITDATA Validate, vectorize, and remove invalid observations.
deformation = deformation(:);
stress = stress(:);

if numel(deformation) ~= numel(stress)
    error("mechanics:fitting:SizeMismatch", ...
        "Deformation and stress must contain the same number of values.");
end

if isempty(config.weights)
    weights = ones(size(stress));
else
    weights = config.weights(:);
    if numel(weights) ~= numel(stress)
        error("mechanics:fitting:InvalidWeights", ...
            "Weights must contain one value per observation.");
    end
end

valid = isfinite(deformation) & isfinite(stress) & isfinite(weights) & weights >= 0;
deformation = deformation(valid);
stress = stress(valid);
weights = weights(valid);

if numel(stress) < 3
    error("mechanics:fitting:InsufficientData", ...
        "At least three finite observations are required.");
end

if all(weights == 0)
    error("mechanics:fitting:InvalidWeights", ...
        "At least one fitting weight must be positive.");
end

weights = weights ./ mean(weights(weights > 0));
end
