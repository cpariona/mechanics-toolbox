function outputFiles = exportFitResidualDiagnostics(diagnostics, outputFolder)
%EXPORTFITRESIDUALDIAGNOSTICS Export residual diagnostics tables and MAT data.
arguments
    diagnostics (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

observationFile = fullfile(outputFolder, "residual_observations.csv");
metricFile = fullfile(outputFolder, "residual_metrics.csv");
dataFile = fullfile(outputFolder, "fit_residual_diagnostics.mat");

writetable(diagnostics.observationSummary, observationFile);
writetable(diagnostics.metricSummary, metricFile);
save(dataFile, "diagnostics");

outputFiles.observations = string(observationFile);
outputFiles.metrics = string(metricFile);
outputFiles.data = string(dataFile);
end
