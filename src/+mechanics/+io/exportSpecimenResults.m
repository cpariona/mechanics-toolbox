function outputFiles = exportSpecimenResults(specimen, outputFolder)
%EXPORTSPECIMENRESULTS Export processed curve, summary, and provenance.
arguments
    specimen (1,1) struct
    outputFolder (1,1) string
end

if ~isfield(specimen, "processed") || ...
        ~isfield(specimen.processed, "strain") || ...
        ~isfield(specimen.processed, "stress")
    error("mechanics:io:MissingProcessedData", ...
        "Specimen must contain processed strain and stress.");
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

safeId = regexprep(string(specimen.id), "[^A-Za-z0-9_-]", "_");
processed = specimen.processed;
observationCount = numel(processed.strain);
if numel(processed.stress) ~= observationCount
    error("mechanics:io:ProcessedSizeMismatch", ...
        "Processed strain and stress must have equal lengths.");
end

curveTable = table( ...
    processed.strain(:), ...
    processed.stress(:), ...
    'VariableNames', {'Strain', 'Stress'});

curveTable = localPrependOptionalColumn( ...
    curveTable, processed, "force", "Force", observationCount);
curveTable = localPrependOptionalColumn( ...
    curveTable, processed, "displacement", "Displacement", observationCount);
curveTable = localAppendOptionalColumn( ...
    curveTable, processed, "currentArea", "CurrentArea", observationCount);
curveTable = localAppendOptionalColumn( ...
    curveTable, processed, "areaScale", "AreaScale", observationCount);

if isfield(specimen, "analysis") && ...
        isfield(specimen.analysis, "tangentModulus") && ...
        isfield(specimen.analysis.tangentModulus, "tangentModulus")
    tangent = specimen.analysis.tangentModulus.tangentModulus;
    if numel(tangent) == observationCount
        curveTable.TangentModulus = tangent(:);
    end
end
if isfield(specimen, "analysis") && ...
        isfield(specimen.analysis, "geometryUncertainty")
    uncertainty = specimen.analysis.geometryUncertainty;
    curveTable = localAppendOptionalColumn(curveTable, uncertainty, ...
        "strainStandardUncertainty", "StrainStandardUncertainty", ...
        observationCount);
    curveTable = localAppendOptionalColumn(curveTable, uncertainty, ...
        "stressStandardUncertainty", "StressStandardUncertainty", ...
        observationCount);
    curveTable = localAppendOptionalColumn(curveTable, uncertainty, ...
        "strainRelativeStandardUncertainty", ...
        "StrainRelativeStandardUncertainty", observationCount);
    curveTable = localAppendOptionalColumn(curveTable, uncertainty, ...
        "stressRelativeStandardUncertainty", ...
        "StressRelativeStandardUncertainty", observationCount);
end

curveFile = fullfile(outputFolder, safeId + "_curve.csv");
writetable(curveTable, curveFile);

summaryFile = fullfile(outputFolder, safeId + "_summary.mat");
save(summaryFile, "specimen");

historyFile = fullfile(outputFolder, safeId + "_history.csv");
if isfield(specimen, "processingHistory") && ...
        ~isempty(specimen.processingHistory)
    historyTable = struct2table(specimen.processingHistory);
else
    historyTable = table();
end
writetable(historyTable, historyFile);

outputFiles.curve = string(curveFile);
outputFiles.summary = string(summaryFile);
outputFiles.history = string(historyFile);
end

function tableValue = localAppendOptionalColumn( ...
        tableValue, source, sourceField, outputName, observationCount)
if ~isfield(source, sourceField)
    return;
end
values = source.(sourceField);
if numel(values) ~= observationCount
    error("mechanics:io:ProcessedSizeMismatch", ...
        "Optional processed field %s must match the stress-strain length.", ...
        sourceField);
end
tableValue.(outputName) = values(:);
end

function tableValue = localPrependOptionalColumn( ...
        tableValue, source, sourceField, outputName, observationCount)
if ~isfield(source, sourceField)
    return;
end
values = source.(sourceField);
if numel(values) ~= observationCount
    error("mechanics:io:ProcessedSizeMismatch", ...
        "Optional processed field %s must match the stress-strain length.", ...
        sourceField);
end
tableValue = addvars(tableValue, values(:), ...
    "Before", 1, "NewVariableNames", outputName);
end
