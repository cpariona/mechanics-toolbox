function specimen = processUniaxialSpecimen(specimen, geometry, config)
%PROCESSUNIAXIALSPECIMEN Run the stable uniaxial processing pipeline.
arguments
    specimen (1,1) struct
    geometry (1,1) struct
    config (1,1) struct
end

if ~isfield(specimen, "raw") || ...
        ~isfield(specimen.raw, "force") || ...
        ~isfield(specimen.raw, "displacement")
    error("mechanics:workflow:InvalidSpecimen", ...
        "Specimen must contain raw.force and raw.displacement.");
end
requiredConfig = ["preprocessing", "mechanics", "analysis"];
if ~all(isfield(config, requiredConfig))
    error("mechanics:workflow:InvalidConfig", ...
        "Config must contain preprocessing, mechanics, and analysis.");
end

rawCurve.force = specimen.raw.force;
rawCurve.displacement = specimen.raw.displacement;
if isfield(specimen.raw, "time")
    rawCurve.time = specimen.raw.time;
end
if isfield(specimen.raw, "currentArea")
    rawCurve.currentArea = specimen.raw.currentArea;
end

if isfield(specimen.raw, "units")
    rawCurve.units = specimen.raw.units;
else
    rawCurve.units = struct();
    if isfield(specimen, "source")
        if isfield(specimen.source, "forceUnit")
            rawCurve.units.force = string(specimen.source.forceUnit);
        end
        if isfield(specimen.source, "displacementUnit")
            rawCurve.units.displacement = string(specimen.source.displacementUnit);
        end
        if isfield(specimen.source, "timeUnit")
            rawCurve.units.time = string(specimen.source.timeUnit);
        end
    end
end

[rawCurve.force, rawCurve.displacement, rawCurve.units, unitConversion] = ...
    mechanics.io.normalizeRawMechanicalUnits( ...
        rawCurve.force, rawCurve.displacement, rawCurve.units);

processedCurve = mechanics.preprocessing.prepareCurve( ...
    rawCurve, config.preprocessing);
processedCurve = mechanics.analysis.computeUniaxialMeasures( ...
    processedCurve, geometry, config.mechanics);
analysisResult = mechanics.analysis.computeTangentModulus( ...
    processedCurve, config.analysis);
analysisResult.units = processedCurve.units.stress;

specimen.geometry = geometry;
specimen.processed = processedCurve;
specimen.analysis.tangentModulus = analysisResult;

if localGeometryUncertaintyEnabled(config)
    specimen.analysis.geometryUncertainty = ...
        mechanics.analysis.computeGeometryUncertainty( ...
            processedCurve, geometry, config.mechanics, ...
            config.uncertainty.geometry);
    specimen.analysis.geometryUncertainty.units.strain = ...
        processedCurve.units.strain;
    specimen.analysis.geometryUncertainty.units.stress = ...
        processedCurve.units.stress;
end

specimen.unitConversion = unitConversion;
specimen.processingConfig = config;
specimen.processingHistory(end + 1) = localHistoryEntry( ...
    "uniaxial-processing", ...
    "Normalized units, prepared the curve, computed stress-strain measures, and estimated tangent modulus.");
if localGeometryUncertaintyEnabled(config)
    specimen.processingHistory(end + 1) = localHistoryEntry( ...
        "geometry-uncertainty", ...
        "Propagated initial-length and initial-area standard uncertainties to strain and stress.");
end
end

function enabled = localGeometryUncertaintyEnabled(config)
enabled = isfield(config, "uncertainty") && ...
    isfield(config.uncertainty, "geometry") && ...
    isfield(config.uncertainty.geometry, "enabled") && ...
    logical(config.uncertainty.geometry.enabled);
end

function entry = localHistoryEntry(stepName, description)
entry.timestamp = datetime("now");
entry.step = string(stepName);
entry.description = string(description);
end
