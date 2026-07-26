function study = runCompressionSpecimen(inputValue, config)
%RUNCOMPRESSIONSPECIMEN Process one selected compression loading branch.
arguments
    inputValue
    config (1,1) struct = mechanics.config.compressionSpecimenConfig()
end

[specimen, sourceFile] = localInputSpecimen(inputValue, config.import);
geometry = localResolveGeometry(specimen, config.geometry);

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
fullCycleMagnitude.displacement = fullCycleMagnitude.displacement - ...
    min(fullCycleMagnitude.displacement);
cycleMetrics = mechanics.analysis.computeCompressionCycleMetrics( ...
    fullCycleMagnitude, relativeLoadingEndIndex, geometry);

% The maintained mechanical state uses physical compression signs.
selectedRaw.force = -forceOrientation .* selectedRaw.force;
selectedRaw.displacement = ...
    -displacementOrientation .* selectedRaw.displacement;

% Cycle detection can include a few leading machine-jitter observations before
% monotonic loading begins. Start the analyzed branch at its least-compressed
% displacement so first-sample zeroing cannot create positive compression strain.
[selectedRaw, leadingTrimCount] = localTrimLeadingDisplacementReversal( ...
    selectedRaw, config.cycle.minimumObservations);
if isfield(cycle, "selectedIndices") && leadingTrimCount > 0
    cycle.selectedIndices = cycle.selectedIndices(leadingTrimCount + 1:end);
end
cycle.leadingTrimCount = leadingTrimCount;

specimen.originalRaw = specimen.raw;
specimen.fullCycleRaw = fullCycleMagnitude;
specimen.raw = selectedRaw;
specimen.cycleSelection = rmfield(cycle, "selectedRaw");
specimen.cycleMetrics = cycleMetrics;
specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, config.processing);

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

study.sourceFile = sourceFile;
study.specimen = specimen;
study.cycle = specimen.cycleSelection;
study.cycleMetrics = cycleMetrics;
study.config = config;
study.config.geometry = geometry;
study.createdAt = datetime("now");

if config.export.enabled
    study.outputFiles = mechanics.io.exportCompressionStudy(study, config.export);
end
end

function [specimen, sourceFile] = localInputSpecimen(inputValue, importConfig)
sourceFile = "";
if isstruct(inputValue) && isscalar(inputValue) && isfield(inputValue, "raw")
    specimen = inputValue;
    if isfield(specimen, "source") && ...
            isfield(specimen.source, "filename")
        sourceFile = string(specimen.source.filename);
    end
    return;
end

if ~(ischar(inputValue) || (isstring(inputValue) && isscalar(inputValue)))
    error("mechanics:workflow:InvalidCompressionSpecimenInput", ...
        "Compression specimen input must be a filename or extracted specimen.");
end

sourceFile = string(inputValue);
if ~isfile(sourceFile)
    error("mechanics:workflow:CompressionFileNotFound", ...
        "Input file does not exist: %s", sourceFile);
end
specimen = mechanics.io.readSpecimenTable(sourceFile, importConfig);
end

function geometry = localResolveGeometry(specimen, configuredGeometry)
geometry = configuredGeometry;
if (~isfinite(geometry.initialLength) || geometry.initialLength <= 0) && ...
        isfield(specimen, "geometry") && ...
        isfield(specimen.geometry, "initialLength")
    geometry.initialLength = specimen.geometry.initialLength;
end
if (~isfinite(geometry.initialArea) || geometry.initialArea <= 0) && ...
        isfield(specimen, "geometry") && ...
        isfield(specimen.geometry, "initialArea")
    geometry.initialArea = specimen.geometry.initialArea;
end
if ~isfinite(geometry.initialLength) || geometry.initialLength <= 0 || ...
        ~isfinite(geometry.initialArea) || geometry.initialArea <= 0
    error("mechanics:workflow:InvalidCompressionGeometry", ...
        "Compression geometry requires positive initialLength and initialArea.");
end
end

function [output, trimCount] = localTrimLeadingDisplacementReversal(input, minimumObservations)
displacement = input.displacement(:);
[~, startIndex] = max(displacement);
trimCount = startIndex - 1;
if trimCount == 0
    output = input;
    return;
end
indices = (startIndex:numel(displacement))';
if numel(indices) < minimumObservations
    error("mechanics:workflow:CompressionBranchTooShortAfterTrim", ...
        ["Removing leading displacement reversal leaves fewer than %d " ...
        "compression observations."], minimumObservations);
end
output = localSubsetRaw(input, indices);
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
