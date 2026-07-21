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

curveTable = table( ...
    specimen.processed.strain(:), ...
    specimen.processed.stress(:), ...
    'VariableNames', {'Strain', 'Stress'});

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
