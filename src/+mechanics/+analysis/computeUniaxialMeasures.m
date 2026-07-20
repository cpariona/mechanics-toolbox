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
switch lower(string(config.strainMeasure))
    case "engineering"
        strain = engineeringStrain;
    case "true"
        strain = log1p(engineeringStrain);
    otherwise
        error("mechanics:analysis:UnknownStrainMeasure", "Unknown strain measure: %s", config.strainMeasure);
end
switch lower(string(config.stressMeasure))
    case "engineering"
        stress = engineeringStress;
    case "true"
        stress = engineeringStress .* (1 + engineeringStrain);
    otherwise
        error("mechanics:analysis:UnknownStressMeasure", "Unknown stress measure: %s", config.stressMeasure);
end
curve.engineeringStrain = engineeringStrain;
curve.engineeringStress = engineeringStress;
curve.strain = strain;
curve.stress = stress;
curve.geometry = geometry;
curve.mechanicsConfig = config;
end

function mustHavePositiveScalar(value, fieldName)
if ~isfield(value, fieldName) || ~isscalar(value.(fieldName)) || ~isfinite(value.(fieldName)) || value.(fieldName) <= 0
    error("mechanics:analysis:InvalidGeometry", "geometry.%s must be a positive finite scalar.", fieldName);
end
end
