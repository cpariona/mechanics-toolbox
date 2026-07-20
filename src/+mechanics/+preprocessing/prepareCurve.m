function curve = prepareCurve(rawCurve, config)
%PREPARECURVE Clean and prepare force-displacement data without overwriting raw data.
mechanics.io.validateRawCurve(rawCurve);
force = rawCurve.force(:);
displacement = rawCurve.displacement(:);
originalIndex = (1:numel(force))';
if config.removeNonfinite
    valid = isfinite(force) & isfinite(displacement);
    force = force(valid);
    displacement = displacement(valid);
    originalIndex = originalIndex(valid);
end
startIndex = max(1, round(config.startIndex));
endIndex = min(numel(force), round(config.endIndex));
if isinf(config.endIndex), endIndex = numel(force); end
if startIndex > endIndex
    error("mechanics:preprocessing:InvalidWindow", "startIndex must not exceed endIndex.");
end
force = force(startIndex:endIndex);
displacement = displacement(startIndex:endIndex);
originalIndex = originalIndex(startIndex:endIndex);
if config.zeroForce, force = force - force(1); end
if config.zeroDisplacement, displacement = displacement - displacement(1); end
if config.smoothing.enabled
    force = mechanics.internal.smoothVector(force, config.smoothing);
    displacement = mechanics.internal.smoothVector(displacement, config.smoothing);
end
curve.raw = rawCurve;
curve.force = force;
curve.displacement = displacement;
curve.originalIndex = originalIndex;
curve.units = mechanics.internal.defaultUnits(rawCurve);
curve.processingConfig = config;
curve.processingHistory = mechanics.internal.buildProcessingHistory(config);
end
