function study = runCompressionStudy(inputValue, config)
%RUNCOMPRESSIONSTUDY Process one multi-specimen compression study.
arguments
    inputValue
    config (1,1) struct = mechanics.config.compressionStudyConfig()
end

[entries, manifest, inputInfo] = localNormalizeInput(inputValue, config);
records = repmat(localEmptyRecord(), numel(entries), 1);

for index = 1:numel(entries)
    records(index).index = index;
    records(index).specimenId = entries(index).specimenId;
    records(index).sheetName = entries(index).sheetName;
    if ~entries(index).include
        records(index).status = "skipped";
        continue;
    end

    try
        specimenConfig = config.specimen;
        specimenConfig.geometry.initialLength = entries(index).initialLength;
        specimenConfig.geometry.initialArea = entries(index).initialArea;
        specimenConfig.export.enabled = false;

        if entries(index).hasSpecimen
            specimenStudy = mechanics.workflow.runCompressionSpecimen( ...
                entries(index).specimen, specimenConfig);
        else
            specimenConfig.import.specimenId = entries(index).specimenId;
            if strlength(entries(index).sheetName) > 0
                specimenConfig.import.sheet = entries(index).sheetName;
            end
            specimenStudy = mechanics.workflow.runCompressionSpecimen( ...
                entries(index).filename, specimenConfig);
        end

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

study.sourceFile = inputInfo.primarySource;
study.sourceFiles = inputInfo.sourceFiles;
study.input = inputInfo;
study.manifest = manifest;
study.analysis = analysis;
study.population = population;
study.populationStatus = populationStatus;
study.populationErrorIdentifier = populationErrorIdentifier;
study.populationErrorMessage = populationErrorMessage;
study.config = config;
study.createdAt = datetime("now");
end

function [entries, manifest, inputInfo] = localNormalizeInput(inputValue, config)
inputType = localResolveInputType(inputValue, config.input.type);

switch inputType
    case "dataset"
        dataset = mechanics.extraction.validateExtractedDataset(inputValue);
        [entries, manifest, sourceFiles] = localDatasetEntries(dataset);

    case "workbook"
        filename = string(inputValue);
        if ~isfile(filename)
            error("mechanics:workflow:CompressionWorkbookNotFound", ...
                "Compression workbook does not exist: %s", filename);
        end
        dataset = mechanics.extraction.extractWorkbook( ...
            filename, config.extraction);
        [entries, manifest, sourceFiles] = localDatasetEntries(dataset);

    case "file-list"
        filenames = string(inputValue(:));
        if isempty(filenames)
            error("mechanics:workflow:EmptyCompressionFileList", ...
                "The compression workbook file list cannot be empty.");
        end
        entries = repmat(localEmptyEntry(), 0, 1);
        manifests = cell(numel(filenames), 1);
        for fileIndex = 1:numel(filenames)
            if ~isfile(filenames(fileIndex))
                error("mechanics:workflow:CompressionWorkbookNotFound", ...
                    "Compression workbook does not exist: %s", ...
                    filenames(fileIndex));
            end
            dataset = mechanics.extraction.extractWorkbook( ...
                filenames(fileIndex), config.extraction);
            [fileEntries, manifests{fileIndex}] = localDatasetEntries(dataset);
            entries = [entries; fileEntries(:)]; %#ok<AGROW>
        end
        manifest = vertcat(manifests{:});
        sourceFiles = filenames;

    case "manifest"
        manifest = localManifest(inputValue, config.defaultInitialLength);
        entries = localManifestEntries(manifest);
        sourceFiles = unique(manifest.File(manifest.Include), "stable");

    otherwise
        error("mechanics:workflow:UnknownCompressionStudyInputType", ...
            "Unknown compression-study input type: %s", inputType);
end

inputInfo.type = inputType;
inputInfo.sourceFiles = string(sourceFiles(:));
inputInfo.primarySource = "";
if ~isempty(inputInfo.sourceFiles)
    inputInfo.primarySource = inputInfo.sourceFiles(1);
end
inputInfo.specimenCount = numel(entries);
end

function inputType = localResolveInputType(inputValue, requestedType)
requestedType = lower(string(requestedType));
if requestedType ~= "auto"
    inputType = requestedType;
    return;
end
if isstruct(inputValue) && isscalar(inputValue) && ...
        isfield(inputValue, "specimens")
    inputType = "dataset";
elseif istable(inputValue)
    inputType = "manifest";
elseif ischar(inputValue) || isstring(inputValue)
    values = string(inputValue);
    if numel(values) > 1
        inputType = "file-list";
        return;
    end
    [~, ~, extension] = fileparts(values);
    if ismember(lower(string(extension)), [".xlsx", ".xls", ".xlsm"])
        inputType = "workbook";
    else
        inputType = "manifest";
    end
else
    error("mechanics:workflow:InvalidCompressionStudyInput", ...
        "Compression study input must be a workbook, file list, manifest, or extracted dataset.");
end
end

function [entries, manifest, sourceFiles] = localDatasetEntries(dataset)
specimens = dataset.specimens(:);
entries = repmat(localEmptyEntry(), numel(specimens), 1);
File = strings(numel(specimens), 1);
SpecimenId = strings(numel(specimens), 1);
InitialLength = nan(numel(specimens), 1);
InitialArea = nan(numel(specimens), 1);
Include = true(numel(specimens), 1);
Sheet = strings(numel(specimens), 1);

for index = 1:numel(specimens)
    specimen = specimens(index);
    entries(index).hasSpecimen = true;
    entries(index).specimen = specimen;
    entries(index).specimenId = string(specimen.id);
    entries(index).initialLength = specimen.geometry.initialLength;
    entries(index).initialArea = specimen.geometry.initialArea;
    if isfield(specimen, "sheetName")
        entries(index).sheetName = string(specimen.sheetName);
    elseif isfield(specimen, "source") && isfield(specimen.source, "sheet")
        entries(index).sheetName = string(specimen.source.sheet);
    end
    if isfield(specimen, "source") && isfield(specimen.source, "filename")
        entries(index).filename = string(specimen.source.filename);
    end

    if strlength(entries(index).specimenId) == 0
        entries(index).specimenId = entries(index).sheetName;
    end
    localValidateEntry(entries(index));

    File(index) = entries(index).filename;
    SpecimenId(index) = entries(index).specimenId;
    InitialLength(index) = entries(index).initialLength;
    InitialArea(index) = entries(index).initialArea;
    Sheet(index) = entries(index).sheetName;
end

if numel(unique(SpecimenId)) ~= numel(SpecimenId)
    error("mechanics:workflow:DuplicateCompressionSpecimenId", ...
        "Specimen identifiers must be unique within one compression study.");
end
manifest = table(File, SpecimenId, InitialLength, InitialArea, Include, Sheet);
sourceFiles = unique(File(strlength(File) > 0), "stable");
end

function entries = localManifestEntries(manifest)
entries = repmat(localEmptyEntry(), height(manifest), 1);
for index = 1:height(manifest)
    entries(index).filename = manifest.File(index);
    entries(index).specimenId = manifest.SpecimenId(index);
    entries(index).initialLength = manifest.InitialLength(index);
    entries(index).initialArea = manifest.InitialArea(index);
    entries(index).include = manifest.Include(index);
    entries(index).sheetName = manifest.Sheet(index);
    localValidateEntry(entries(index));
end
end

function manifest = localManifest(inputValue, defaultLength)
if istable(inputValue)
    manifest = inputValue;
elseif ischar(inputValue) || (isstring(inputValue) && isscalar(inputValue))
    filename = string(inputValue);
    if ~isfile(filename)
        error("mechanics:workflow:CompressionManifestNotFound", ...
            "Compression manifest does not exist: %s", filename);
    end
    manifest = readtable(filename, "VariableNamingRule", "preserve");
else
    error("mechanics:workflow:InvalidCompressionManifestInput", ...
        "Compression manifest input must be a table or filename.");
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
if ~ismember("Sheet", names)
    manifest.Sheet = strings(height(manifest), 1);
else
    manifest.Sheet = string(manifest.Sheet);
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

function localValidateEntry(entry)
if strlength(strtrim(entry.specimenId)) == 0
    error("mechanics:workflow:InvalidCompressionSpecimenId", ...
        "Compression specimen identifiers must be nonempty.");
end
if ~isfinite(entry.initialLength) || entry.initialLength <= 0 || ...
        ~isfinite(entry.initialArea) || entry.initialArea <= 0
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

function entry = localEmptyEntry()
entry.filename = "";
entry.specimenId = "";
entry.sheetName = "";
entry.initialLength = NaN;
entry.initialArea = NaN;
entry.include = true;
entry.hasSpecimen = false;
entry.specimen = struct();
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