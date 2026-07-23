function curve = prepareCurve(rawCurve, config)
%PREPARECURVE Clean and prepare force-displacement data without overwriting raw data.
mechanics.io.validateRawCurve(rawCurve);
force = rawCurve.force(:);
displacement = rawCurve.displacement(:);
originalIndex = (1:numel(force))';

hasCurrentArea = isfield(rawCurve, "currentArea");
if hasCurrentArea
    currentArea = rawCurve.currentArea(:);
    if numel(currentArea) ~= numel(force)
        error("mechanics:preprocessing:CurrentAreaSizeMismatch", ...
            "rawCurve.currentArea must match force and displacement length.");
    end
else
    currentArea = [];
end

if config.removeNonfinite
    valid = isfinite(force) & isfinite(displacement);
    if hasCurrentArea
        valid = valid & isfinite(currentArea);
    end
    force = force(valid);
    displacement = displacement(valid);
    originalIndex = originalIndex(valid);
    if hasCurrentArea
        currentArea = currentArea(valid);
    end
end

startIndex = max(1, round(config.startIndex));
if isinf(config.endIndex)
    endIndex = numel(force);
else
    endIndex = min(numel(force), round(config.endIndex));
end
if startIndex > endIndex
    error("mechanics:preprocessing:InvalidWindow", ...
        "startIndex must not exceed endIndex.");
end

force = force(startIndex:endIndex);
displacement = displacement(startIndex:endIndex);
originalIndex = originalIndex(startIndex:endIndex);
if hasCurrentArea
    currentArea = currentArea(startIndex:endIndex);
end

[referenceIndex, referenceMethod] = localReferenceIndex(force, config);
referenceForce = force(referenceIndex);
referenceDisplacement = displacement(referenceIndex);

if config.zeroReference.trimBeforeReference
    force = force(referenceIndex:end);
    displacement = displacement(referenceIndex:end);
    originalIndex = originalIndex(referenceIndex:end);
    if hasCurrentArea
        currentArea = currentArea(referenceIndex:end);
    end
    referenceIndexInOutput = 1;
else
    referenceIndexInOutput = referenceIndex;
end

if referenceMethod ~= "none"
    force = force - referenceForce;
    displacement = displacement - referenceDisplacement;
end

if config.smoothing.enabled
    force = mechanics.internal.smoothVector(force, config.smoothing);
    displacement = mechanics.internal.smoothVector(displacement, config.smoothing);
end

curve.raw = rawCurve;
curve.force = force;
curve.displacement = displacement;
if hasCurrentArea
    curve.currentAreaMeasured = currentArea;
end
curve.originalIndex = originalIndex;
curve.units = mechanics.internal.defaultUnits(rawCurve);
curve.processingConfig = config;
curve.processingHistory = mechanics.internal.buildProcessingHistory(config);
curve.zeroReference.method = referenceMethod;
curve.zeroReference.inputIndex = referenceIndex;
curve.zeroReference.outputIndex = referenceIndexInOutput;
curve.zeroReference.originalIndex = originalIndex(referenceIndexInOutput);
curve.zeroReference.force = referenceForce;
curve.zeroReference.displacement = referenceDisplacement;
end

function [referenceIndex, method] = localReferenceIndex(force, config)
if ~isfield(config, "zeroReference")
    referenceIndex = 1;
    method = "first-sample";
    return;
end

zeroConfig = config.zeroReference;
method = lower(string(zeroConfig.method));

switch method
    case "first-sample"
        referenceIndex = 1;

    case "manual-index"
        referenceIndex = round(zeroConfig.manualIndex);
        if ~isscalar(referenceIndex) || ~isfinite(referenceIndex) || ...
                referenceIndex < 1 || referenceIndex > numel(force)
            error("mechanics:preprocessing:InvalidZeroReferenceIndex", ...
                "zeroReference.manualIndex must identify an available sample.");
        end

    case "preload-threshold"
        threshold = zeroConfig.preloadForce;
        sustainedPoints = max(1, round(zeroConfig.sustainedPoints));
        above = force >= threshold;
        runStart = conv(double(above), ones(sustainedPoints, 1), "valid");
        referenceIndex = find(runStart == sustainedPoints, 1, "first");
        if isempty(referenceIndex)
            error("mechanics:preprocessing:PreloadNotReached", ...
                "The force signal never reached the configured preload threshold %.6g.", ...
                threshold);
        end

    case "none"
        referenceIndex = 1;

    otherwise
        error("mechanics:preprocessing:UnknownZeroReferenceMethod", ...
            "Unknown zero-reference method: %s", method);
end
end
