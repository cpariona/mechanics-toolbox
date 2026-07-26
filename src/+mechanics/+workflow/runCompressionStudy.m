function study = runCompressionStudy(manifestInput, config)
%RUNCOMPRESSIONSTUDY Process one compression study from a specimen manifest.
arguments
    manifestInput
    config (1,1) struct = mechanics.config.compressionStudyConfig()
end

[manifest, sourceFile] = localManifest( ...
    manifestInput, config.defaultInitialLength);
records = repmat(localEmptyRecord(), height(manifest), 1);

for index = 1:height(manifest)
    records(index).index = index;
    records(index).specimenId = manifest.SpecimenId(index);
    records(index).sheetName = manifest.File(index);
    if ~manifest.Include(index)
        records(index).status = "skipped";
        continue;
    end

    try
        specimenConfig = config.specimen;
        specimenConfig.import.specimenId = manifest.SpecimenId(index);
        specimenConfig.geometry.initialLength = manifest.InitialLength(index);
        specimenConfig.geometry.initialArea = manifest.InitialArea(index);
        specimenConfig.export.enabled = false;

        specimenStudy = mechanics.workflow.runCompressionSpecimen( ...
            manifest.File(index), specimenConfig);
        records(index).status = "processed";
        records(index).specimen = specimenStudy.specimen;
        records(index).cycle = specimenStudy.cycle;
        records(index).cycleMetrics = specimenStudy.cycleMetrics;
    catch ME
        records(index).status = "failed";
        records(index).errorIdentifier = string(ME.identifier);
        records(index).errorMessage = string(ME.message);
        if ~config.continueOnError
            rethrow(ME);
        end
    end
end

analysis.records = records;
analysis.summary = localSummary(records);
analysis.createdAt = datetime("now");

population = struct();
populationStatus = "disabled";
populationErrorIdentifier = "";
populationErrorMessage = "";
if config.population.enabled
    try
        population = mechanics.workflow.analyzeSpecimenPopulation( ...
            analysis, config.population.config);
        populationStatus = "completed";
    catch ME
        populationStatus = "failed";
        populationErrorIdentifier = string(ME.identifier);
        populationErrorMessage = string(ME.message);
        if ~config.population.continueOnError
            rethrow(ME);
        end
    end
end

study.sourceFile = sourceFile;
study.sourceFiles = unique(manifest.File(manifest.Include), "stable");
study.manifest = manifest;
study.analysis = analysis;
study.population = population;
study.populationStatus = populationStatus;
study.populationErrorIdentifier = populationErrorIdentifier;
study.populationErrorMessage = populationErrorMessage;
study.config = config;
study.createdAt = datetime("now");
end

function [manifest, sourceFile] = localManifest(input, defaultLength)
sourceFile = "";
if istable(input)
    manifest = input;
elseif ischar(input) || (isstring(input) && isscalar(input))
    sourceFile = string(input);
    if ~isfile(sourceFile)
        error("mechanics:workflow:CompressionManifestNotFound", ...
            "Compression manifest does not exist: %s", sourceFile);
    end
    manifest = readtable(sourceFile, "VariableNamingRule", "preserve");
else
    error("mechanics:workflow:InvalidCompressionStudyInput", ...
        "Compression study input must be a manifest table or filename.");
end

required = ["File", "SpecimenId", "InitialArea"];
names = string(manifest.Properties.VariableNames);
if ~all(ismember(required, names))
    error("mechanics:workflow:InvalidCompressionStudyManifest", ...
        "Manifest requires File, SpecimenId, and InitialArea columns.");
end
manifest.File = string(manifest.File);
manifest.SpecimenId = string(manifest.SpecimenId);
if ~ismember("InitialLength", names)
    manifest.InitialLength = repmat(defaultLength, height(manifest), 1);
end
if ~ismember("Include", names)
    manifest.Include = true(height(manifest), 1);
else
    manifest.Include = logical(manifest.Include);
end
if any(strlength(strtrim(manifest.File)) == 0) || ...
        any(strlength(strtrim(manifest.SpecimenId)) == 0)
    error("mechanics:workflow:InvalidCompressionStudyManifest", ...
        "File and SpecimenId values must be nonempty.");
end
if numel(unique(manifest.SpecimenId)) ~= height(manifest)
    error("mechanics:workflow:DuplicateCompressionSpecimenId", ...
        "SpecimenId values must be unique within one compression study.");
end
if any(~isfinite(manifest.InitialLength) | manifest.InitialLength <= 0) || ...
        any(~isfinite(manifest.InitialArea) | manifest.InitialArea <= 0)
    error("mechanics:workflow:InvalidCompressionStudyGeometry", ...
        "InitialLength and InitialArea must be positive finite values.");
end
end

function summary = localSummary(records)
count = numel(records);
Index = (1:count)';
SpecimenId = string({records.specimenId})';
Status = string({records.status})';
ObservationCount = nan(count, 1);
MaximumStrain = nan(count, 1);
MaximumStress = nan(count, 1);
MedianTangentModulus = nan(count, 1);
SelectedModel = strings(count, 1);
ErrorIdentifier = string({records.errorIdentifier})';
ErrorMessage = string({records.errorMessage})';

for index = 1:count
    if records(index).status ~= "processed"
        continue;
    end
    specimen = records(index).specimen;
    metrics = records(index).cycleMetrics;
    ObservationCount(index) = numel(specimen.processed.strain);
    MaximumStrain(index) = metrics.peakStrain;
    MaximumStress(index) = metrics.peakStress;
    MedianTangentModulus(index) = ...
        specimen.analysis.tangentModulus.medianModulus;
    if isfield(specimen, "modelSelection") && ...
            specimen.modelSelection.selection.hasEligibleModel
        SelectedModel(index) = specimen.modelSelection.selection.bestModel;
    end
end

summary = table(Index, SpecimenId, Status, ObservationCount, ...
    MaximumStrain, MaximumStress, MedianTangentModulus, SelectedModel, ...
    ErrorIdentifier, ErrorMessage);
end

function record = localEmptyRecord()
record.index = NaN;
record.specimenId = "";
record.sheetName = "";
record.status = "pending";
record.specimen = struct();
record.cycle = struct();
record.cycleMetrics = struct();
record.errorIdentifier = "";
record.errorMessage = "";
record.group = "";
end
