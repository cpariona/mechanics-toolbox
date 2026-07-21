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

processedCurve = mechanics.preprocessing.prepareCurve( ...
    rawCurve, config.preprocessing);

processedCurve = mechanics.analysis.computeUniaxialMeasures( ...
    processedCurve, geometry, config.mechanics);

analysisResult = mechanics.analysis.computeTangentModulus( ...
    processedCurve, config.analysis);

specimen.geometry = geometry;
specimen.processed = processedCurve;
specimen.analysis.tangentModulus = analysisResult;
specimen.processingConfig = config;
specimen.processingHistory(end + 1) = localHistoryEntry( ...
    "uniaxial-processing", ...
    "Prepared the curve, computed stress-strain measures, and estimated tangent modulus.");
end

function entry = localHistoryEntry(stepName, description)
entry.timestamp = datetime("now");
entry.step = string(stepName);
entry.description = string(description);
end
