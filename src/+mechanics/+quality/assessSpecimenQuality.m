function quality = assessSpecimenQuality(specimen, config)
%ASSESSSPECIMENQUALITY Evaluate basic quality of raw force-displacement data.
arguments
    specimen (1,1) struct
    config (1,1) struct
end

if ~isfield(specimen, "raw") || ...
        ~isfield(specimen.raw, "force") || ...
        ~isfield(specimen.raw, "displacement")
    error("mechanics:quality:InvalidSpecimen", ...
        "Specimen must contain raw.force and raw.displacement.");
end

force = specimen.raw.force(:);
displacement = specimen.raw.displacement(:);

if numel(force) ~= numel(displacement)
    error("mechanics:quality:SizeMismatch", ...
        "Force and displacement must have equal lengths.");
end

observationCount = numel(force);
finiteMask = isfinite(force) & isfinite(displacement);
finiteCount = nnz(finiteMask);
nonfiniteFraction = 1 - finiteCount ./ max(observationCount, 1);

finiteForce = force(finiteMask);
finiteDisplacement = displacement(finiteMask);

if finiteCount > 0
    forceRange = max(finiteForce) - min(finiteForce);
    displacementRange = max(finiteDisplacement) - min(finiteDisplacement);
else
    forceRange = NaN;
    displacementRange = NaN;
end

if finiteCount >= 2
    displacementSteps = diff(finiteDisplacement);
    nonzeroSteps = displacementSteps(displacementSteps ~= 0);

    if isempty(nonzeroSteps)
        reversalFraction = 0;
        monotonicIncreasing = true;
    else
        reversalFraction = nnz(nonzeroSteps < 0) ./ numel(nonzeroSteps);
        monotonicIncreasing = all(nonzeroSteps >= 0);
    end
else
    reversalFraction = NaN;
    monotonicIncreasing = false;
end

checks.minimumObservations = ...
    finiteCount >= config.minimumObservations;
checks.nonfiniteFraction = ...
    nonfiniteFraction <= config.maximumNonfiniteFraction;
checks.displacementRange = ...
    isfinite(displacementRange) && ...
    displacementRange >= config.minimumDisplacementRange;
checks.forceRange = ...
    isfinite(forceRange) && forceRange >= config.minimumForceRange;
checks.displacementReversals = ...
    isfinite(reversalFraction) && ...
    reversalFraction <= config.maximumDisplacementReversalFraction;

if config.requireMonotonicDisplacement
    checks.monotonicDisplacement = monotonicIncreasing;
else
    checks.monotonicDisplacement = true;
end

checkNames = string(fieldnames(checks));
checkValues = false(numel(checkNames), 1);
for index = 1:numel(checkNames)
    checkValues(index) = checks.(checkNames(index));
end

failedChecks = checkNames(~checkValues);

quality.passed = all(checkValues);
quality.checks = checks;
quality.failedChecks = failedChecks;
quality.observationCount = observationCount;
quality.finiteObservationCount = finiteCount;
quality.nonfiniteFraction = nonfiniteFraction;
quality.forceRange = forceRange;
quality.displacementRange = displacementRange;
quality.displacementReversalFraction = reversalFraction;
quality.monotonicIncreasing = monotonicIncreasing;
quality.config = config;
end
