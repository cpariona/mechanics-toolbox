function result = computeGeometryUncertainty(curve, geometry, mechanicsConfig, uncertaintyConfig)
%COMPUTEGEOMETRYUNCERTAINTY Propagate initial-geometry uncertainty to strain and stress.
arguments
    curve (1,1) struct
    geometry (1,1) struct
    mechanicsConfig (1,1) struct
    uncertaintyConfig (1,1) struct
end

requiredCurveFields = ["force", "displacement"];
if ~all(isfield(curve, requiredCurveFields))
    error("mechanics:analysis:MissingUncertaintyCurveData", ...
        "curve must contain force and displacement.");
end

mustHavePositiveScalar(geometry, "initialLength");
mustHavePositiveScalar(geometry, "initialArea");

lengthStd = localStandardUncertainty(uncertaintyConfig, "initialLengthStd");
areaStd = localStandardUncertainty(uncertaintyConfig, "initialAreaStd");
if lengthStd == 0 && areaStd == 0
    error("mechanics:analysis:MissingGeometryUncertainty", ...
        "At least one positive geometry standard uncertainty is required.");
end

nominal = mechanics.analysis.computeUniaxialMeasures( ...
    curve, geometry, mechanicsConfig);

strainVariance = zeros(size(nominal.strain));
stressVariance = zeros(size(nominal.stress));

if lengthStd > 0
    step = localFiniteDifferenceStep(geometry.initialLength, lengthStd);
    lowerGeometry = geometry;
    upperGeometry = geometry;
    lowerGeometry.initialLength = geometry.initialLength - step;
    upperGeometry.initialLength = geometry.initialLength + step;
    if lowerGeometry.initialLength <= 0
        lowerGeometry.initialLength = geometry.initialLength;
        lower = nominal;
        upper = mechanics.analysis.computeUniaxialMeasures( ...
            curve, upperGeometry, mechanicsConfig);
        strainDerivative = (upper.strain - lower.strain) ./ step;
        stressDerivative = (upper.stress - lower.stress) ./ step;
    else
        lower = mechanics.analysis.computeUniaxialMeasures( ...
            curve, lowerGeometry, mechanicsConfig);
        upper = mechanics.analysis.computeUniaxialMeasures( ...
            curve, upperGeometry, mechanicsConfig);
        strainDerivative = (upper.strain - lower.strain) ./ (2 .* step);
        stressDerivative = (upper.stress - lower.stress) ./ (2 .* step);
    end
    strainVariance = strainVariance + (strainDerivative .* lengthStd).^2;
    stressVariance = stressVariance + (stressDerivative .* lengthStd).^2;
end

if areaStd > 0
    step = localFiniteDifferenceStep(geometry.initialArea, areaStd);
    lowerGeometry = geometry;
    upperGeometry = geometry;
    lowerGeometry.initialArea = geometry.initialArea - step;
    upperGeometry.initialArea = geometry.initialArea + step;
    if lowerGeometry.initialArea <= 0
        lowerGeometry.initialArea = geometry.initialArea;
        lower = nominal;
        upper = mechanics.analysis.computeUniaxialMeasures( ...
            curve, upperGeometry, mechanicsConfig);
        strainDerivative = (upper.strain - lower.strain) ./ step;
        stressDerivative = (upper.stress - lower.stress) ./ step;
    else
        lower = mechanics.analysis.computeUniaxialMeasures( ...
            curve, lowerGeometry, mechanicsConfig);
        upper = mechanics.analysis.computeUniaxialMeasures( ...
            curve, upperGeometry, mechanicsConfig);
        strainDerivative = (upper.strain - lower.strain) ./ (2 .* step);
        stressDerivative = (upper.stress - lower.stress) ./ (2 .* step);
    end
    strainVariance = strainVariance + (strainDerivative .* areaStd).^2;
    stressVariance = stressVariance + (stressDerivative .* areaStd).^2;
end

strainStd = sqrt(strainVariance);
stressStd = sqrt(stressVariance);

result.strainStandardUncertainty = strainStd;
result.stressStandardUncertainty = stressStd;
result.strainRelativeStandardUncertainty = localRelative(strainStd, nominal.strain);
result.stressRelativeStandardUncertainty = localRelative(stressStd, nominal.stress);
result.initialLengthStd = lengthStd;
result.initialAreaStd = areaStd;
result.method = "first-order-central-difference";
result.config = uncertaintyConfig;
end

function value = localStandardUncertainty(config, fieldName)
value = 0;
if ~isfield(config, fieldName) || isempty(config.(fieldName)) || ...
        isnan(config.(fieldName))
    return;
end
candidate = config.(fieldName);
if ~isscalar(candidate) || ~isfinite(candidate) || candidate < 0
    error("mechanics:analysis:InvalidGeometryUncertainty", ...
        "%s must be NaN or a nonnegative finite scalar.", fieldName);
end
value = candidate;
end

function step = localFiniteDifferenceStep(value, standardUncertainty)
step = max(abs(value) .* 1e-6, standardUncertainty .* 1e-3);
step = max(step, eps(value) .^ 0.5 .* max(1, abs(value)));
end

function relative = localRelative(standardUncertainty, nominal)
relative = nan(size(nominal));
mask = isfinite(nominal) & nominal ~= 0;
relative(mask) = abs(standardUncertainty(mask) ./ nominal(mask));
relative(nominal == 0 & standardUncertainty == 0) = 0;
end

function mustHavePositiveScalar(value, fieldName)
if ~isfield(value, fieldName) || ~isscalar(value.(fieldName)) || ...
        ~isfinite(value.(fieldName)) || value.(fieldName) <= 0
    error("mechanics:analysis:InvalidGeometry", ...
        "geometry.%s must be a positive finite scalar.", fieldName);
end
end
