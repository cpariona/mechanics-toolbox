function [dataset, inputInfo] = normalizeTensileStudyInput(inputValue, config)
%NORMALIZETENSILESTUDYINPUT Normalize supported inputs to one dataset contract.
arguments
    inputValue
    config (1,1) struct = mechanics.config.tensileStudyConfig()
end

inputType = localResolveInputType(inputValue, config.input.type);

switch inputType
    case "dataset"
        dataset = mechanics.extraction.validateExtractedDataset(inputValue);
        sourceFiles = localDatasetSourceFiles(dataset);

    case "workbook"
        filename = string(inputValue);
        dataset = mechanics.extraction.extractWorkbook(filename, config.extraction);
        sourceFiles = filename;

    case "file-list"
        filenames = string(inputValue(:));
        if isempty(filenames)
            error("mechanics:workflow:EmptyStudyFileList", ...
                "The tensile-study file list cannot be empty.");
        end
        specimens = struct([]);
        for index = 1:numel(filenames)
            extracted = mechanics.extraction.extractWorkbook( ...
                filenames(index), config.extraction);
            specimens = localAppendSpecimens(specimens, extracted.specimens);
        end
        dataset.specimens = specimens;
        dataset.source.type = "file-list";
        dataset.source.files = filenames;
        dataset = mechanics.extraction.validateExtractedDataset(dataset);
        sourceFiles = filenames;

    case "manifest"
        manifest = localManifest(inputValue);
        specimens = struct([]);
        includedRows = find(manifest.Include);
        for outputIndex = 1:numel(includedRows)
            rowIndex = includedRows(outputIndex);
            importConfig = localManifestImportConfig( ...
                config.input.manifestImportConfig, manifest, rowIndex);
            specimen = mechanics.io.readSpecimenTable( ...
                manifest.File(rowIndex), importConfig);
            specimen.geometry.initialLength = manifest.InitialLength(rowIndex);
            specimen.geometry.initialArea = manifest.InitialArea(rowIndex);
            specimen.testType = manifest.TestType(rowIndex);
            specimen.sheetName = string(manifest.Sheet(rowIndex));
            specimen.source.manifestRow = rowIndex;
            specimens = localAppendSpecimens(specimens, specimen);
        end
        if isempty(specimens)
            error("mechanics:workflow:EmptyIncludedManifest", ...
                "The manifest does not contain any included specimens.");
        end
        dataset.specimens = specimens;
        dataset.source.type = "manifest";
        dataset.source.manifest = manifest;
        dataset = mechanics.extraction.validateExtractedDataset(dataset);
        sourceFiles = unique(manifest.File(manifest.Include), "stable");

    otherwise
        error("mechanics:workflow:UnknownStudyInputType", ...
            "Unknown tensile-study input type: %s", inputType);
end

inputInfo.type = inputType;
inputInfo.sourceFiles = string(sourceFiles(:));
inputInfo.primarySource = "";
if ~isempty(inputInfo.sourceFiles)
    inputInfo.primarySource = inputInfo.sourceFiles(1);
end
inputInfo.specimenCount = numel(dataset.specimens);
end

function inputType = localResolveInputType(inputValue, requestedType)
requestedType = lower(string(requestedType));
if requestedType ~= "auto"
    inputType = requestedType;
    return;
end
if isstruct(inputValue) && isscalar(inputValue) && isfield(inputValue,"specimens")
    inputType = "dataset";
elseif istable(inputValue)
    inputType = "manifest";
elseif ischar(inputValue) || isstring(inputValue)
    values = string(inputValue);
    if numel(values) == 1
        inputType = "workbook";
    else
        inputType = "file-list";
    end
else
    error("mechanics:workflow:UnsupportedStudyInput", ...
        "Input must be a workbook, file list, manifest, or extracted dataset.");
end
end

function manifest = localManifest(inputValue)
if istable(inputValue)
    manifest = mechanics.workflow.validateBatchManifest(inputValue);
elseif ischar(inputValue) || isstring(inputValue)
    manifest = mechanics.io.readBatchManifest(string(inputValue));
else
    error("mechanics:workflow:InvalidManifestInput", ...
        "Manifest input must be a table or a manifest filename.");
end
end

function importConfig = localManifestImportConfig(baseConfig, manifest, rowIndex)
importConfig = baseConfig;
importConfig.specimenId = manifest.SpecimenId(rowIndex);
importConfig.sheet = manifest.Sheet(rowIndex);
importConfig.forceScale = manifest.ForceScale(rowIndex);
importConfig.displacementScale = manifest.DisplacementScale(rowIndex);
importConfig.timeScale = manifest.TimeScale(rowIndex);
importConfig.currentAreaScale = manifest.CurrentAreaScale(rowIndex);
importConfig.forceColumns = localPreferredColumn( ...
    manifest.ForceColumn(rowIndex), importConfig.forceColumns);
importConfig.displacementColumns = localPreferredColumn( ...
    manifest.DisplacementColumn(rowIndex), importConfig.displacementColumns);
importConfig.timeColumns = localPreferredColumn( ...
    manifest.TimeColumn(rowIndex), importConfig.timeColumns);
importConfig.currentAreaColumns = localPreferredColumn( ...
    manifest.CurrentAreaColumn(rowIndex), importConfig.currentAreaColumns);
end

function columns = localPreferredColumn(preferred, fallback)
preferred = strtrim(string(preferred));
columns = string(fallback);
if strlength(preferred) > 0
    columns = unique([preferred, columns], "stable");
end
end

function output = localAppendSpecimens(output, input)
input = input(:);
if isempty(output)
    output = input;
else
    output = [output(:); input]; %#ok<AGROW>
end
end

function sourceFiles = localDatasetSourceFiles(dataset)
sourceFiles = strings(0,1);
for index = 1:numel(dataset.specimens)
    specimen = dataset.specimens(index);
    if isfield(specimen,"source") && isfield(specimen.source,"filename")
        filename = string(specimen.source.filename);
        if strlength(filename) > 0
            sourceFiles(end+1,1) = filename; %#ok<AGROW>
        end
    end
end
sourceFiles = unique(sourceFiles,"stable");
end
