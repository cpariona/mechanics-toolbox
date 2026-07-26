function study = runCompressionSpecimen(filename, config)
%RUNCOMPRESSIONSPECIMEN Process one selected compression loading branch.
arguments
    filename (1,1) string
    config (1,1) struct = mechanics.config.compressionSpecimenConfig()
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

relativeLoadingEndIndex = ...
    cycle.loadingEndIndex - cycle.cycleStartIndex + 1;
localValidateSignConvention(config.signConvention);
[forceOrientation, displacementOrientation] = ...
    localCompressionOrientation(fullCycleRaw, relativeLoadingEndIndex);

% Cycle metrics are presentation magnitudes and do not define stored signs.
fullCycleMagnitude = fullCycleRaw;
fullCycleMagnitude.force = forceOrientation .* fullCycleRaw.force;
fullCycleMagnitude.displacement = ...
    displacementOrientation .* fullCycleRaw.displacement;
cycleMetrics = mechanics.analysis.computeCompressionCycleMetrics( ...
    fullCycleMagnitude, relativeLoadingEndIndex, config.geometry);

% The maintained mechanical state uses physical compression signs.
selectedRaw.force = -forceOrientation .* selectedRaw.force;
selectedRaw.displacement = ...
    -displacementOrientation .* selectedRaw.displacement;

specimen.originalRaw = specimen.raw;
specimen.fullCycleRaw = fullCycleMagnitude;
specimen.raw = selectedRaw;
specimen.cycleSelection = rmfield(cycle, "selectedRaw");
specimen.cycleMetrics = cycleMetrics;
specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, config.geometry, config.processing);

if config.fitting.enabled
    specimen.modelSelection = mechanics.fitting.fitAcrossWindows( ...
        config.fitting.modelNames, specimen.processed.strain, ...
        specimen.processed.stress, config.fitting.context, ...
        config.fitting.fitConfig, config.fitting.selectionConfig);

    monteCarloConfig = config.fitting.measurementMonteCarlo;
    if monteCarloConfig.enabled && ...
            specimen.modelSelection.selection.hasEligibleModel
        selectedRecord = localSelectedFitRecord(specimen.modelSelection);
        specimen.measurementMonteCarloFit = ...
            mechanics.fitting.measurementMonteCarloFitUncertainty( ...
                specimen, selectedRecord.fitResult, monteCarloConfig);
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
modelMask = string({records.modelName}) == string(selection.bestModel);
successMask = [records.succeeded];
candidates = find(modelMask & successMask);
if isempty(candidates)
    error("mechanics:workflow:SelectedCompressionFitMissing", ...
        "The selected compression fit record could not be resolved.");
end
[~, localIndex] = max([records(candidates).windowFraction]);
record = records(candidates(localIndex));
end

function localValidateSignConvention(value)
value = lower(string(value));
if ~ismember(value, ["positive-compression", "instrument"])
    error("mechanics:workflow:UnknownCompressionSignConvention", ...
        "Unknown compression sign convention: %s", value);
end
end

function [forceOrientation, displacementOrientation] = ...
        localCompressionOrientation(raw, loadingEndIndex)
forceOrientation = localPositiveLoadingOrientation( ...
    raw.force, loadingEndIndex);
displacementOrientation = localPositiveLoadingOrientation( ...
    raw.displacement, loadingEndIndex);
end

function orientation = localPositiveLoadingOrientation(input, loadingEndIndex)
input = input(:);
loadingIncrement = input(loadingEndIndex) - input(1);
if loadingIncrement < 0
    orientation = -1;
else
    orientation = 1;
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
