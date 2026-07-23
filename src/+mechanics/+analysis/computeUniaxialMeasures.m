function curve = computeUniaxialMeasures(curve, geometry, config)
%COMPUTEUNIAXIALMEASURES Compute uniaxial engineering or true stress and strain.
arguments
    curve (1,1) struct
    geometry (1,1) struct
    config (1,1) struct
end
mustHavePositiveScalar(geometry, "initialLength");
mustHavePositiveScalar(geometry, "initialArea");

engineeringStrain = curve.displacement ./ geometry.initialLength;
engineeringStress = curve.force ./ geometry.initialArea;
stretch = 1 + engineeringStrain;
if any(~isfinite(stretch) | stretch <= 0)
    error("mechanics:analysis:InvalidStretch", ...
        "The processed displacement produces nonpositive stretch values.");
end

switch lower(string(config.strainMeasure))
    case "engineering"
        strain = engineeringStrain;
    case "true"
        strain = log(stretch);
    otherwise
        error("mechanics:analysis:UnknownStrainMeasure", ...
            "Unknown strain measure: %s", config.strainMeasure);
end

switch lower(string(config.stressMeasure))
    case "engineering"
        stress = engineeringStress;
        currentArea = repmat(geometry.initialArea, size(stretch));
        areaScale = ones(size(stretch));
    case "true"
        [currentArea, areaScale] = localCurrentArea( ...
            curve, geometry.initialArea, stretch, config);
        stress = engineeringStress ./ areaScale;
    otherwise
        error("mechanics:analysis:UnknownStressMeasure", ...
            "Unknown stress measure: %s", config.stressMeasure);
end

curve.engineeringStrain = engineeringStrain;
curve.engineeringStress = engineeringStress;
curve.stretch = stretch;
curve.currentArea = currentArea;
curve.areaScale = areaScale;
curve.strain = strain;
curve.stress = stress;
curve.geometry = geometry;
curve.mechanicsConfig = config;
end

function [currentArea, areaScale] = localCurrentArea(curve, initialArea, stretch, config)
method = "incompressible";
if isfield(config, "areaEvolution")
    method = lower(string(config.areaEvolution));
end
switch method
    case "incompressible"
        areaScale = stretch .^ (-1);
        currentArea = initialArea .* areaScale;
    case "poisson-power"
        if ~isfield(config, "poissonRatio") || ...
                ~isscalar(config.poissonRatio) || ...
                ~isfinite(config.poissonRatio) || ...
                config.poissonRatio < 0 || config.poissonRatio > 0.5
            error("mechanics:analysis:InvalidPoissonRatio", ...
                "poissonRatio must lie between 0 and 0.5.");
        end
        areaScale = stretch .^ (-2 .* config.poissonRatio);
        currentArea = initialArea .* areaScale;
    case "measured-area"
        if ~isfield(curve, "currentAreaMeasured")
            error("mechanics:analysis:MissingMeasuredArea", ...
                "areaEvolution='measured-area' requires a measured current-area vector.");
        end
        currentArea = curve.currentAreaMeasured(:);
        if numel(currentArea) ~= numel(stretch)
            error("mechanics:analysis:MeasuredAreaSizeMismatch", ...
                "Measured current area must match the processed curve length.");
        end
        if any(~isfinite(currentArea) | currentArea <= 0)
            error("mechanics:analysis:InvalidMeasuredArea", ...
                "Measured current area must contain positive finite values.");
        end
        areaScale = currentArea ./ initialArea;
    otherwise
        error("mechanics:analysis:UnknownAreaEvolution", ...
            "Unknown area-evolution method: %s", method);
end
end

function mustHavePositiveScalar(value, fieldName)
if ~isfield(value, fieldName) || ~isscalar(value.(fieldName)) || ...
        ~isfinite(value.(fieldName)) || value.(fieldName) <= 0
    error("mechanics:analysis:InvalidGeometry", ...
        "geometry.%s must be a positive finite scalar.", fieldName);
end
end
