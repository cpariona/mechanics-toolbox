function outputFiles = exportFitIdentifiability(diagnostics, outputFolder)
%EXPORTFITIDENTIFIABILITY Export diagnostics tables and MAT data.
arguments
    diagnostics (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

parameterFile = fullfile(outputFolder, "parameter_identifiability.csv");
correlationFile = fullfile(outputFolder, "parameter_correlation.csv");
pairFile = fullfile(outputFolder, "high_correlation_pairs.csv");
dataFile = fullfile(outputFolder, "fit_identifiability.mat");

writetable(diagnostics.parameterSummary, parameterFile);

names = string(diagnostics.parameterSummary.Parameter);
correlationTable = array2table(diagnostics.correlationMatrix, ...
    "VariableNames", matlab.lang.makeValidName(cellstr(names)), ...
    "RowNames", cellstr(names));
writetable(correlationTable, correlationFile, "WriteRowNames", true);
writetable(diagnostics.highCorrelationPairs, pairFile);
save(dataFile, "diagnostics");

outputFiles.parameters = string(parameterFile);
outputFiles.correlation = string(correlationFile);
outputFiles.highCorrelationPairs = string(pairFile);
outputFiles.data = string(dataFile);
end
