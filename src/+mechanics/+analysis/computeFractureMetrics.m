function metrics = computeFractureMetrics(specimen, config)
%COMPUTEFRACTUREMETRICS Compute peak and post-peak tensile fracture metrics.
arguments
    specimen (1,1) struct
    config (1,1) struct = mechanics.config.fractureAnalysisConfig()
end

if ~isfield(specimen, "raw") || ...
        ~isfield(specimen.raw, "force") || ...
        ~isfield(specimen.raw, "displacement")
    error("mechanics:analysis:InvalidFractureSpecimen", ...
        "Specimen must contain raw.force and raw.displacement.");
end

force = specimen.raw.force(:);
displacement = specimen.raw.displacement(:);

if numel(force) ~= numel(displacement)
    error("mechanics:analysis:FractureSizeMismatch", ...
        "Force and displacement must have equal lengths.");
end

finiteMask = isfinite(force) & isfinite(displacement);
finiteIndices = find(finiteMask);

if numel(finiteIndices) < config.minimumObservations
    error("mechanics:analysis:InsufficientFractureData", ...
        "At least %d finite observations are required.", ...
        config.minimumObservations);
end

forceFinite = force(finiteMask);
displacementFinite = displacement(finiteMask);

[peakForce, localPeakIndex] = max(forceFinite);
peakIndex = finiteIndices(localPeakIndex);
peakDisplacement = displacement(peakIndex);

postPeakForce = force(peakIndex:end);
postPeakForce = postPeakForce(isfinite(postPeakForce));

if isempty(postPeakForce) || peakForce <= 0
    minimumPostPeakForce = NaN;
    finalForce = NaN;
    postPeakDropFraction = NaN;
    residualForceFraction = NaN;
else
    minimumPostPeakForce = min(postPeakForce);
    finalForce = postPeakForce(end);
    postPeakDropFraction = ...
        (peakForce - minimumPostPeakForce) ./ peakForce;
    residualForceFraction = finalForce ./ peakForce;
end

fractureDetected = isfinite(postPeakDropFraction) && ...
    postPeakDropFraction >= config.fractureDetectionDropFraction;

completeFracture = fractureDetected && ...
    postPeakDropFraction >= config.completeFractureDropFraction && ...
    residualForceFraction <= config.residualForceFraction;

prePeakDisplacement = displacement(1:peakIndex);
prePeakForce = force(1:peakIndex);
validPrePeak = isfinite(prePeakDisplacement) & isfinite(prePeakForce);
prePeakDisplacement = prePeakDisplacement(validPrePeak);
prePeakForce = prePeakForce(validPrePeak);

fullDisplacement = displacementFinite;
fullForce = forceFinite;

if config.integrateAbsoluteDisplacement
    energyToPeak = trapz(abs(prePeakDisplacement), prePeakForce);
    totalRecordedEnergy = trapz(abs(fullDisplacement), fullForce);
else
    energyToPeak = trapz(prePeakDisplacement, prePeakForce);
    totalRecordedEnergy = trapz(fullDisplacement, fullForce);
end

peakStress = NaN;
peakStrain = NaN;

if isfield(specimen, "processed") && ...
        isfield(specimen.processed, "stress") && ...
        isfield(specimen.processed, "strain")
    peakStress = max(specimen.processed.stress);
    peakStrain = specimen.processed.strain(end);
elseif isfield(specimen, "geometry") && ...
        isfield(specimen.geometry, "initialArea") && ...
        isfield(specimen.geometry, "initialLength") && ...
        isfinite(specimen.geometry.initialArea) && ...
        isfinite(specimen.geometry.initialLength)
    peakStress = peakForce ./ specimen.geometry.initialArea;
    peakStrain = peakDisplacement ./ specimen.geometry.initialLength;
end

energyDensityToPeak = NaN;
if isfield(specimen, "geometry") && ...
        isfield(specimen.geometry, "initialArea") && ...
        isfield(specimen.geometry, "initialLength") && ...
        isfinite(specimen.geometry.initialArea) && ...
        isfinite(specimen.geometry.initialLength)
    initialVolume = ...
        specimen.geometry.initialArea .* specimen.geometry.initialLength;

    if initialVolume > 0
        energyDensityToPeak = energyToPeak ./ initialVolume;
    end
end

metrics.peakIndex = peakIndex;
metrics.peakForce = peakForce;
metrics.peakDisplacement = peakDisplacement;
metrics.peakStress = peakStress;
metrics.peakStrain = peakStrain;
metrics.minimumPostPeakForce = minimumPostPeakForce;
metrics.finalForce = finalForce;
metrics.postPeakDropFraction = postPeakDropFraction;
metrics.residualForceFraction = residualForceFraction;
metrics.fractureDetected = fractureDetected;
metrics.completeFracture = completeFracture;
metrics.energyToPeak = energyToPeak;
metrics.totalRecordedEnergy = totalRecordedEnergy;
metrics.energyDensityToPeak = energyDensityToPeak;
metrics.config = config;
end
