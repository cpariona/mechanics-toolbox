function metrics = computeCompressionCycleMetrics(fullCycleRaw, loadingEndIndex, geometry)
%COMPUTECOMPRESSIONCYCLEMETRICS Compute loading, unloading, and hysteresis metrics.
arguments
    fullCycleRaw (1,1) struct
    loadingEndIndex (1,1) double
    geometry (1,1) struct
end

if ~isfield(fullCycleRaw, "force") || ~isfield(fullCycleRaw, "displacement")
    error("mechanics:analysis:InvalidCompressionCycle", ...
        "fullCycleRaw must contain force and displacement.");
end
force = fullCycleRaw.force(:);
displacement = fullCycleRaw.displacement(:);
if numel(force) ~= numel(displacement)
    error("mechanics:analysis:CompressionCycleSizeMismatch", ...
        "Force and displacement must have equal lengths.");
end
if loadingEndIndex < 2 || loadingEndIndex > numel(force)
    error("mechanics:analysis:InvalidCompressionLoadingEnd", ...
        "loadingEndIndex must identify the loading peak inside the cycle.");
end

loadingDisplacement = displacement(1:loadingEndIndex);
loadingForce = force(1:loadingEndIndex);
unloadingDisplacement = displacement(loadingEndIndex:end);
unloadingForce = force(loadingEndIndex:end);

loadingEnergy = trapz(loadingDisplacement, loadingForce);
unloadingSignedEnergy = trapz(unloadingDisplacement, unloadingForce);
recoveredEnergy = abs(unloadingSignedEnergy);
hysteresisEnergy = loadingEnergy - recoveredEnergy;
if isfinite(loadingEnergy) && loadingEnergy ~= 0
    hysteresisFraction = hysteresisEnergy ./ loadingEnergy;
else
    hysteresisFraction = NaN;
end

[peakForce, peakIndex] = max(force);
peakDisplacement = displacement(peakIndex);
peakStress = NaN;
peakStrain = NaN;
energyDensity = NaN;
if isfield(geometry, "initialArea") && isfield(geometry, "initialLength") && ...
        isfinite(geometry.initialArea) && geometry.initialArea > 0 && ...
        isfinite(geometry.initialLength) && geometry.initialLength > 0
    peakStress = peakForce ./ geometry.initialArea;
    peakStrain = peakDisplacement ./ geometry.initialLength;
    energyDensity = hysteresisEnergy ./ ...
        (geometry.initialArea .* geometry.initialLength);
end

metrics.peakIndex = peakIndex;
metrics.peakForce = peakForce;
metrics.peakDisplacement = peakDisplacement;
metrics.peakStress = peakStress;
metrics.peakStrain = peakStrain;
metrics.loadingEnergy = loadingEnergy;
metrics.recoveredEnergy = recoveredEnergy;
metrics.hysteresisEnergy = hysteresisEnergy;
metrics.hysteresisFraction = hysteresisFraction;
metrics.hysteresisEnergyDensity = energyDensity;
metrics.loadingObservationCount = loadingEndIndex;
metrics.unloadingObservationCount = numel(force) - loadingEndIndex + 1;
metrics.units.force = "N";
metrics.units.displacement = "mm";
metrics.units.stress = "MPa";
metrics.units.strain = "-";
metrics.units.energy = "mJ";
metrics.units.energyDensity = "MPa";
end