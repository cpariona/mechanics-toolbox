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
selectedRaw = cycle.selectedRaw;

signConvention = lower(string(config.signConvention));
switch signConvention
    case "positive-compression"
        selectedRaw.force = localPositiveIncrement(selectedRaw.force);
        selectedRaw.displacement = localPositiveIncrement(selectedRaw.displacement);
    case "instrument"
        % Preserve imported signs.
    otherwise
        error("mechanics:workflow:UnknownCompressionSignConvention", ...
            "Unknown compression sign convention: %s", config.signConvention);
end

specimen.originalRaw = specimen.raw;
specimen.raw = selectedRaw;
specimen.cycleSelection = rmfield(cycle, "selectedRaw");
specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, config.geometry, config.processing);

study.sourceFile = filename;
study.specimen = specimen;
study.cycle = specimen.cycleSelection;
study.config = config;
study.createdAt = datetime("now");

if config.export.enabled
    folder = string(config.export.outputFolder);
    if ~isfolder(folder)
        mkdir(folder);
    end
    study.outputFiles = mechanics.io.exportSpecimenResults(specimen, folder);
    save(fullfile(folder, "compression_study.mat"), "study");
    study.outputFiles.study = fullfile(folder, "compression_study.mat");
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