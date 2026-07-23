function study = runCompressionStudy(filename, config)
%RUNCOMPRESSIONSTUDY Process the selected branch of a compression cycle.
arguments
    filename (1,1) string
    config (1,1) struct = mechanics.config.compressionStudyConfig()
end

if ~isfile(filename)
    error("mechanics:workflow:CompressionFileNotFound", ...
        "Input file does not exist: %s", filename);
end
if ~isfinite(config.geometry.initialLength) || ...
        config.geometry.initialLength <= 0 || ...
        ~isfinite(config.geometry.initialArea) || ...
        config.geometry.initialArea <= 0
    error("mechanics:workflow:InvalidCompressionGeometry", ...
        "Compression geometry requires positive initialLength and initialArea.");
end

specimen = mechanics.io.readSpecimenTable(filename, config.import);
specimen.testType = "compression";
cycle = mechanics.segmentation.selectCompressionCycle( ...
    specimen.raw, config.cycle);

fullCycleIndices = (cycle.cycleStartIndex:cycle.cycleEndIndex)';
fullCycleRaw = localSubsetRaw(specimen.raw, fullCycleIndices);
selectedRaw = cycle.selectedRaw;

signConvention = lower(string(config.signConvention));
switch signConvention
    case "positive-compression"
        fullCycleRaw.force = localPositiveIncrement(fullCycleRaw.force);
        fullCycleRaw.displacement = localPositiveIncrement(fullCycleRaw.displacement);
        selectedRaw.force = localPositiveIncrement(selectedRaw.force);
        selectedRaw.displacement = localPositiveIncrement(selectedRaw.displacement);
    case "instrument"
        % Preserve imported signs.
    otherwise
        error("mechanics:workflow:UnknownCompressionSignConvention", ...
            "Unknown compression sign convention: %s", config.signConvention);
end

relativeLoadingEndIndex = ...
    cycle.loadingEndIndex - cycle.cycleStartIndex + 1;
cycleMetrics = mechanics.analysis.computeCompressionCycleMetrics( ...
    fullCycleRaw, relativeLoadingEndIndex, config.geometry);

specimen.originalRaw = specimen.raw;
specimen.fullCycleRaw = fullCycleRaw;
specimen.raw = selectedRaw;
specimen.cycleSelection = rmfield(cycle, "selectedRaw");
specimen.cycleMetrics = cycleMetrics;
specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, config.geometry, config.processing);

study.sourceFile = filename;
study.specimen = specimen;
study.cycle = specimen.cycleSelection;
study.cycleMetrics = cycleMetrics;
study.config = config;
study.createdAt = datetime("now");

if config.export.enabled
    study.outputFiles = mechanics.io.exportCompressionStudy(study, config.export);
end
end

function output = localPositiveIncrement(input)
input = input(:);
if input(end) - input(1) < 0
    output = -input;
else
    output = input;
end
end

function output = localSubsetRaw(raw, indices)
output.force = raw.force(indices);
output.displacement = raw.displacement(indices);
if isfield(raw, "time")
    output.time = raw.time(indices);
end
if isfield(raw, "units")
    output.units = raw.units;
end
end