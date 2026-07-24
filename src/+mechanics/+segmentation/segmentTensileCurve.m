function result = segmentTensileCurve(rawCurve, config)
%SEGMENTTENSILECURVE Select the loading region up to a configured peak fraction.
arguments
    rawCurve (1,1) struct
    config (1,1) struct = mechanics.config.curveSegmentationConfig()
end

if ~isfield(rawCurve, "force") || ~isfield(rawCurve, "displacement")
    error("mechanics:segmentation:InvalidRawCurve", ...
        "rawCurve must contain force and displacement.");
end

force = rawCurve.force(:);
displacement = rawCurve.displacement(:);
if numel(force) ~= numel(displacement)
    error("mechanics:segmentation:SizeMismatch", ...
        "Force and displacement must have equal lengths.");
end

observationCount = numel(force);
finiteMask = isfinite(force) & isfinite(displacement);
if nnz(finiteMask) < config.minimumObservations
    error("mechanics:segmentation:InsufficientObservations", ...
        "At least %d finite observations are required.", ...
        config.minimumObservations);
end

finiteIndices = find(finiteMask);
finiteForce = force(finiteMask);
[peakForce, localPeakIndex] = max(finiteForce);
peakIndex = finiteIndices(localPeakIndex);
peakDisplacement = displacement(peakIndex);

if ~config.enabled
    analysisEndIndex = observationCount;
    method = "disabled";
else
    method = lower(string(config.method));
    switch method
        case "pre-peak"
            analysisEndIndex = localResolveAnalysisEnd( ...
                force, peakIndex, peakForce, config.analysisPeakFraction);
        otherwise
            error("mechanics:segmentation:UnknownMethod", ...
                "Unknown segmentation method: %s", config.method);
    end
end

if analysisEndIndex < config.minimumObservations
    error("mechanics:segmentation:InsufficientSegment", ...
        "Segmented curve contains fewer than %d observations.", ...
        config.minimumObservations);
end

postPeakEndIndex = observationCount;
if isfinite(config.postPeakWindow)
    postPeakEndIndex = min(observationCount, ...
        peakIndex + round(config.postPeakWindow));
end
postPeakForce = force(peakIndex:postPeakEndIndex);
postPeakForce = postPeakForce(isfinite(postPeakForce));
if isempty(postPeakForce) || peakForce <= 0
    postPeakDropFraction = NaN;
else
    postPeakDropFraction = ...
        (peakForce - min(postPeakForce)) ./ peakForce;
end

analysisRaw.force = force(1:analysisEndIndex);
analysisRaw.displacement = displacement(1:analysisEndIndex);
if isfield(rawCurve, "units")
    analysisRaw.units = rawCurve.units;
end
if isfield(rawCurve, "time")
    time = rawCurve.time(:);
    if numel(time) ~= observationCount
        error("mechanics:segmentation:TimeSizeMismatch", ...
            "Time must have the same length as force and displacement.");
    end
    analysisRaw.time = time(1:analysisEndIndex);
end

result.method = method;
result.peakIndex = peakIndex;
result.peakForce = peakForce;
result.peakDisplacement = peakDisplacement;
result.analysisEndIndex = analysisEndIndex;
result.analysisPeakFraction = config.analysisPeakFraction;
result.analysisObservationCount = analysisEndIndex;
result.originalObservationCount = observationCount;
result.postPeakDropFraction = postPeakDropFraction;
result.analysisRaw = analysisRaw;
result.config = config;
end

function analysisEndIndex = localResolveAnalysisEnd( ...
        force, peakIndex, peakForce, peakFraction)
if ~isscalar(peakFraction) || ~isfinite(peakFraction) || ...
        peakFraction <= 0 || peakFraction > 1
    error("mechanics:segmentation:InvalidPeakFraction", ...
        "analysisPeakFraction must lie in (0, 1].");
end
if peakFraction == 1
    analysisEndIndex = peakIndex;
    return;
end
threshold = peakFraction .* peakForce;
candidate = find(isfinite(force(1:peakIndex)) & ...
    force(1:peakIndex) >= threshold, 1, "first");
if isempty(candidate)
    analysisEndIndex = peakIndex;
else
    analysisEndIndex = candidate;
end
end