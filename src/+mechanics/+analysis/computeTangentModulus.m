function result = computeTangentModulus(curve, config)
%COMPUTETANGENTMODULUS Estimate tangent modulus over strain-based windows.
if ~isfield(curve, "strain") || ~isfield(curve, "stress")
    error("mechanics:analysis:MissingMeasures", ...
        "Compute stress and strain before tangent modulus.");
end

strain = curve.strain(:);
stress = curve.stress(:);
valid = isfinite(strain) & isfinite(stress);
strain = strain(valid);
stress = stress(valid);

if numel(strain) < config.minimumWindowPoints
    error("mechanics:analysis:InsufficientModulusData", ...
        "Not enough finite observations for tangent-modulus estimation.");
end

[strain, order] = sort(strain, "ascend");
stress = stress(order);
[strain, uniqueIndex] = unique(strain, "stable");
stress = stress(uniqueIndex);

method = lower(string(config.modulusMethod));
smoothedStress = stress;

switch method
    case "local-linear"
        tangentModulus = localPolynomialDerivative( ...
            strain, stress, config.derivativeWindowStrain, ...
            1, config.minimumWindowPoints);

    case "local-quadratic"
        tangentModulus = localPolynomialDerivative( ...
            strain, stress, config.derivativeWindowStrain, ...
            2, config.minimumWindowPoints);

    case "gradient-smoothed"
        smoothedStress = localSmoothByStrain(strain, stress, ...
            config.derivativeSmoothing);
        tangentModulus = gradient(smoothedStress) ./ gradient(strain);

    case "gradient"
        tangentModulus = gradient(stress) ./ gradient(strain);

    otherwise
        error("mechanics:analysis:UnknownModulusMethod", ...
            "Unknown tangent-modulus method: %s", method);
end

summaryRange = config.summaryStrainRange;
if numel(summaryRange) ~= 2 || any(~isfinite(summaryRange)) || ...
        summaryRange(2) < summaryRange(1)
    error("mechanics:analysis:InvalidModulusStrainRange", ...
        "summaryStrainRange must contain two increasing finite values.");
end
summaryMask = strain >= summaryRange(1) & strain <= summaryRange(2);
if ~any(summaryMask)
    error("mechanics:analysis:EmptyModulusStrainRange", ...
        "No processed observations fall inside summaryStrainRange.");
end

result.strain = strain;
result.sourceStress = stress;
result.smoothedStress = smoothedStress;
result.tangentModulus = tangentModulus;
result.tangentModulusForPlot = tangentModulus;
result.medianModulus = median(tangentModulus(summaryMask), "omitnan");
result.meanModulus = mean(tangentModulus(summaryMask), "omitnan");
result.summaryStrainRange = summaryRange;
result.summaryMask = summaryMask;
result.windowIndices = [find(summaryMask, 1, "first"), ...
    find(summaryMask, 1, "last")];
result.config = config;
end

function derivative = localPolynomialDerivative(strain, stress, width, order, minimumPoints)
if ~isscalar(width) || ~isfinite(width) || width <= 0
    error("mechanics:analysis:InvalidDerivativeWindow", ...
        "derivativeWindowStrain must be a positive finite scalar.");
end

derivative = nan(size(strain));
halfWidth = width / 2;
for index = 1:numel(strain)
    mask = abs(strain - strain(index)) <= halfWidth;
    if nnz(mask) < max(minimumPoints, order + 1)
        [~, nearest] = sort(abs(strain - strain(index)), "ascend");
        mask = false(size(strain));
        mask(nearest(1:min(numel(nearest), max(minimumPoints, order + 1)))) = true;
    end
    centered = strain(mask) - strain(index);
    coefficients = polyfit(centered, stress(mask), order);
    derivative(index) = coefficients(end - 1);
end
end

function output = localSmoothByStrain(strain, stress, smoothing)
if ~smoothing.enabled
    output = stress;
    return;
end

spacing = median(diff(strain), "omitnan");
frameLength = max(3, round(smoothing.windowStrain / spacing));
if mod(frameLength, 2) == 0
    frameLength = frameLength + 1;
end
frameLength = min(frameLength, numel(stress) - mod(numel(stress) + 1, 2));
frameLength = max(frameLength, smoothing.polynomialOrder + 2);
if mod(frameLength, 2) == 0
    frameLength = frameLength + 1;
end
frameLength = min(frameLength, numel(stress));
if mod(frameLength, 2) == 0
    frameLength = frameLength - 1;
end

settings.method = smoothing.method;
settings.frameLength = frameLength;
settings.polynomialOrder = min(smoothing.polynomialOrder, frameLength - 1);
output = mechanics.internal.smoothVector(stress, settings);
end