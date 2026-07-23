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

if config.fitting.enabled
    compressionDeformation = -specimen.processed.strain;
    compressionStress = -specimen.processed.stress;
    specimen.modelSelection = mechanics.fitting.fitAcrossWindows( ...
        config.fitting.modelNames, compressionDeformation, ...
        compressionStress, config.fitting.context, ...
        config.fitting.fitConfig, config.fitting.selectionConfig);
    specimen.modelSelection.compressionSignTransform = ...
        "positive compression converted to negative engineering strain and nominal stress";

    monteCarloConfig = config.fitting.geometryMonteCarlo;
    if monteCarloConfig.enabled && specimen.modelSelection.selection.succeeded
        selectedRecord = localSelectedFitRecord(specimen.modelSelection);
        fitSpecimen = specimen;
        fitSpecimen.processed.force = -specimen.processed.force;
        fitSpecimen.processed.displacement = -specimen.processed.displacement;
        fitSpecimen.processed.strain = compressionDeformation;
        fitSpecimen.processed.stress = compressionStress;
        specimen.geometryMonteCarloFit = ...
            mechanics.fitting.geometryMonteCarloFitUncertainty( ...
                fitSpecimen, selectedRecord.fitResult, monteCarloConfig);
    end
end

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

function record = localSelectedFitRecord(modelSelection)
selection = modelSelection.selection;
records = modelSelection.records;
mask = [records.succeeded] & ...
    string({records.modelName}) == string(selection.modelName) & ...
    [records.windowFraction] == selection.windowFraction;
index = find(mask, 1, "first");
if isempty(index)
    error("mechanics:workflow:SelectedCompressionFitMissing", ...
        "The selected compression fit record could not be resolved.");
end
record = records(index);
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
if isfield(raw, "currentArea")
    output.currentArea = raw.currentArea(indices);
end
if isfield(raw, "units")
    output.units = raw.units;
end
end
