function dataset = extractZwickD412Workbook(filename, config)
%EXTRACTZWICKD412WORKBOOK Extract specimens from a Zwick/Roell workbook.
arguments
    filename (1,1) string
    config (1,1) struct
end

sheetNames = string(sheetnames(filename));
matchesSpecimen = ~cellfun( ...
    @isempty, ...
    regexp(cellstr(sheetNames), ...
        char(config.zwick.specimenSheetPattern), "once"));
specimenSheets = sheetNames(matchesSpecimen);

if isempty(specimenSheets)
    error("mechanics:extraction:NoSpecimenSheets", ...
        "No specimen sheets matched pattern %s.", ...
        config.zwick.specimenSheetPattern);
end

resultsSheet = localResolveSheetName( ...
    sheetNames, config.zwick.resultsSheet);
resultsCells = readcell(filename, ...
    "Sheet", resultsSheet, ...
    "UseExcel", false);

metadataRows = localExtractMetadataRows(resultsCells, config.zwick);
specimens = repmat(localEmptySpecimen(), numel(specimenSheets), 1);

for specimenIndex = 1:numel(specimenSheets)
    sheetName = specimenSheets(specimenIndex);
    sheetCells = readcell(filename, ...
        "Sheet", sheetName, ...
        "UseExcel", false);

    [columnNames, units, numericData] = ...
        localExtractSpecimenData(sheetCells, config.zwick);

    displacementIndex = localResolveAlias( ...
        columnNames, config.zwick.displacementAliases, true);
    forceIndex = localResolveAlias( ...
        columnNames, config.zwick.forceAliases, true);

    displacement = numericData(:, displacementIndex);
    force = numericData(:, forceIndex);
    valid = isfinite(displacement) & isfinite(force);

    metadata = localFindMetadata(metadataRows, sheetName);

    specimen = localEmptySpecimen();
    specimen.id = metadata.specimenId;
    if strlength(specimen.id) == 0
        specimen.id = sheetName;
    end

    specimen.sheetName = sheetName;
    specimen.testType = "tension";

    specimen.raw.displacement = displacement(valid);
    specimen.raw.force = force(valid);

    specimen.geometry.initialLength = config.defaultInitialLength;
    specimen.geometry.thickness = metadata.thickness;
    specimen.geometry.width = metadata.width;

    if isfinite(metadata.thickness) && isfinite(metadata.width)
        specimen.geometry.initialArea = ...
            metadata.thickness .* metadata.width;
    else
        specimen.geometry.initialArea = NaN;
    end

    specimen.source.filename = filename;
    specimen.source.sheet = sheetName;
    specimen.source.displacementColumn = ...
        columnNames(displacementIndex);
    specimen.source.forceColumn = columnNames(forceIndex);
    specimen.source.displacementUnit = units(displacementIndex);
    specimen.source.forceUnit = units(forceIndex);
    specimen.source.variableNamesRow = ...
        config.zwick.variableNamesRow;
    specimen.source.unitsRow = config.zwick.unitsRow;
    specimen.source.dataStartRow = config.zwick.dataStartRow;

    specimen.metadata.resultsSheet = resultsSheet;
    specimen.metadata.resultsRow = metadata.rowIndex;
    specimen.metadata.originalSheetLabel = metadata.sheetLabel;

    specimen.processingHistory = localHistoryEntry( ...
        "extraction", ...
        sprintf( ...
            "Extracted %d finite observations from sheet %s.", ...
            nnz(valid), sheetName));

    specimens(specimenIndex) = specimen;
end

dataset.source.filename = filename;
dataset.source.sheetNames = sheetNames;
dataset.source.resultsSheet = resultsSheet;
dataset.specimens = specimens;
dataset.metadata.specimenCount = numel(specimens);
dataset.metadata.extractedAt = datetime("now");
dataset.metadata.configuration = config;
end

function resolved = localResolveSheetName(sheetNames, requested)
matchIndex = find(strcmpi(sheetNames, string(requested)), 1);
if isempty(matchIndex)
    error("mechanics:extraction:MissingResultsSheet", ...
        "Results sheet was not found: %s", requested);
end
resolved = sheetNames(matchIndex);
end

function rows = localExtractMetadataRows(cells, zwickConfig)
startRow = zwickConfig.resultsDataStartRow;
if size(cells, 1) < startRow
    rows = repmat(localEmptyMetadata(), 0, 1);
    return;
end

rows = repmat(localEmptyMetadata(), size(cells, 1) - startRow + 1, 1);
outputIndex = 0;

for rowIndex = startRow:size(cells, 1)
    sheetLabel = localCellString( ...
        cells, rowIndex, zwickConfig.resultsSheetNameColumn);

    if strlength(strtrim(sheetLabel)) == 0
        continue;
    end

    outputIndex = outputIndex + 1;
    rows(outputIndex).rowIndex = rowIndex;
    rows(outputIndex).sheetLabel = sheetLabel;
    rows(outputIndex).specimenId = localCellString( ...
        cells, rowIndex, zwickConfig.specimenIdColumn);
    rows(outputIndex).thickness = localCellNumeric( ...
        cells, rowIndex, zwickConfig.thicknessColumn);
    rows(outputIndex).width = localCellNumeric( ...
        cells, rowIndex, zwickConfig.widthColumn);
end

rows = rows(1:outputIndex);
end

function metadata = localFindMetadata(rows, sheetName)
metadata = localEmptyMetadata();

if isempty(rows)
    metadata.sheetLabel = sheetName;
    return;
end

labels = string({rows.sheetLabel});
matchIndex = find(strcmpi(labels, sheetName), 1);

if isempty(matchIndex)
    normalizedLabels = arrayfun( ...
        @mechanics.io.normalizeColumnName, labels);
    normalizedSheet = mechanics.io.normalizeColumnName(sheetName);
    matchIndex = find(normalizedLabels == normalizedSheet, 1);
end

if ~isempty(matchIndex)
    metadata = rows(matchIndex);
else
    metadata.sheetLabel = sheetName;
end
end

function [columnNames, units, numericData] = ...
        localExtractSpecimenData(cells, zwickConfig)

if size(cells, 1) < zwickConfig.dataStartRow
    error("mechanics:extraction:InsufficientSheetRows", ...
        "Specimen sheet does not contain the configured data start row.");
end

columnCount = size(cells, 2);
columnNames = strings(1, columnCount);
units = strings(1, columnCount);

for columnIndex = 1:columnCount
    columnNames(columnIndex) = localCellString( ...
        cells, zwickConfig.variableNamesRow, columnIndex);
    units(columnIndex) = localCellString( ...
        cells, zwickConfig.unitsRow, columnIndex);
end

lastDataRow = size(cells, 1);
numericData = nan( ...
    lastDataRow - zwickConfig.dataStartRow + 1, ...
    columnCount);

for rowIndex = zwickConfig.dataStartRow:lastDataRow
    outputRow = rowIndex - zwickConfig.dataStartRow + 1;

    for columnIndex = 1:columnCount
        numericData(outputRow, columnIndex) = ...
            localNumericValue(cells{rowIndex, columnIndex});
    end
end
end

function columnIndex = localResolveAlias(columnNames, aliases, required)
normalizedColumns = arrayfun( ...
    @mechanics.io.normalizeColumnName, columnNames);
normalizedAliases = arrayfun( ...
    @mechanics.io.normalizeColumnName, string(aliases));

columnIndex = [];
for aliasIndex = 1:numel(normalizedAliases)
    matchIndex = find( ...
        normalizedColumns == normalizedAliases(aliasIndex), 1);
    if ~isempty(matchIndex)
        columnIndex = matchIndex;
        return;
    end
end

if required
    error("mechanics:extraction:MissingDataColumn", ...
        "None of the requested aliases were found: %s. Columns: %s.", ...
        strjoin(string(aliases), ", "), ...
        strjoin(columnNames, ", "));
end
end

function value = localCellString(cells, rowIndex, columnIndex)
if rowIndex > size(cells, 1) || columnIndex > size(cells, 2)
    value = "";
    return;
end

raw = cells{rowIndex, columnIndex};
isMissingScalar = isscalar(raw) && ismissing(raw);

if isempty(raw) || isMissingScalar
    value = "";
else
    value = string(raw);
end
end

function value = localCellNumeric(cells, rowIndex, columnIndex)
if rowIndex > size(cells, 1) || columnIndex > size(cells, 2)
    value = NaN;
    return;
end
value = localNumericValue(cells{rowIndex, columnIndex});
end

function value = localNumericValue(raw)
if isnumeric(raw) && isscalar(raw)
    value = double(raw);
elseif islogical(raw) && isscalar(raw)
    value = double(raw);
elseif ischar(raw) || isstring(raw)
    value = str2double(string(raw));
else
    value = NaN;
end
end

function metadata = localEmptyMetadata()
metadata.rowIndex = NaN;
metadata.sheetLabel = "";
metadata.specimenId = "";
metadata.thickness = NaN;
metadata.width = NaN;
end

function specimen = localEmptySpecimen()
specimen.id = "";
specimen.sheetName = "";
specimen.testType = "";
specimen.raw = struct();
specimen.geometry = struct();
specimen.source = struct();
specimen.metadata = struct();
specimen.processingHistory = struct( ...
    "timestamp", {}, "step", {}, "description", {});
end

function entry = localHistoryEntry(stepName, description)
entry.timestamp = datetime("now");
entry.step = string(stepName);
entry.description = string(description);
end
