function specimen = readSpecimenTable(filename, config)
%READSPECIMENTABLE Import one mechanical-test specimen from a table file.
arguments
    filename (1,1) string
    config (1,1) struct = mechanics.config.excelImportConfig()
end

if ~isfile(filename)
    error("mechanics:io:FileNotFound", ...
        "Input file does not exist: %s", filename);
end

[~, defaultId, extension] = fileparts(filename);
extension = lower(string(extension));

switch extension
    case {".xlsx", ".xls", ".xlsm"}
        options = detectImportOptions( ...
            filename, ...
            "Sheet", config.sheet, ...
            "VariableNamingRule", localVariableNamingRule(config));

        if strlength(string(config.dataRange)) > 0
            options.DataRange = char(config.dataRange);
        end

        data = readtable(filename, options);

    case {".csv", ".txt"}
        options = detectImportOptions( ...
            filename, ...
            "VariableNamingRule", localVariableNamingRule(config));
        data = readtable(filename, options);

    otherwise
        error("mechanics:io:UnsupportedFileType", ...
            "Unsupported specimen file type: %s", extension);
end

forceName = mechanics.io.resolveColumnName( ...
    data.Properties.VariableNames, config.forceColumns, true);
displacementName = mechanics.io.resolveColumnName( ...
    data.Properties.VariableNames, config.displacementColumns, true);
timeName = mechanics.io.resolveColumnName( ...
    data.Properties.VariableNames, config.timeColumns, false);

force = data.(forceName);
displacement = data.(displacementName);

if ~isnumeric(force) || ~isnumeric(displacement)
    error("mechanics:io:NonNumericData", ...
        "Force and displacement columns must contain numeric values.");
end

force = force(:) .* config.forceScale;
displacement = displacement(:) .* config.displacementScale;

if numel(force) ~= numel(displacement)
    error("mechanics:io:SizeMismatch", ...
        "Force and displacement columns must have equal lengths.");
end

specimenId = string(config.specimenId);
if strlength(specimenId) == 0
    specimenId = string(defaultId);
end

specimen.id = specimenId;
specimen.source.filename = filename;
specimen.source.sheet = config.sheet;
specimen.source.forceColumn = forceName;
specimen.source.displacementColumn = displacementName;
specimen.source.timeColumn = timeName;
specimen.source.importConfig = config;

specimen.raw.force = force;
specimen.raw.displacement = displacement;

if strlength(timeName) > 0
    time = data.(timeName);
    if ~isnumeric(time)
        error("mechanics:io:NonNumericData", ...
            "The selected time column must contain numeric values.");
    end
    specimen.raw.time = time(:) .* config.timeScale;
end

specimen.raw.originalTable = data;
specimen.processingHistory = localHistoryEntry( ...
    "import", ...
    sprintf("Imported %d observations from %s.", numel(force), filename));
end

function rule = localVariableNamingRule(config)
if config.preserveVariableNames
    rule = "preserve";
else
    rule = "modify";
end
end

function entry = localHistoryEntry(stepName, description)
entry.timestamp = datetime("now");
entry.step = string(stepName);
entry.description = string(description);
end
