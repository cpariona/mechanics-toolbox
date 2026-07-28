function files = exportFitDiagnostics(analysis, outputFolder)
%EXPORTFITDIAGNOSTICS Export integrated fit diagnostics and summaries.
arguments
    analysis (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

reliabilityFile = fullfile(outputFolder, "fit_reliability_components.csv");
errorFile = fullfile(outputFolder, "fit_diagnostic_errors.csv");
summaryFile = fullfile(outputFolder, "fit_diagnostics_summary.csv");
dataFile = fullfile(outputFolder, "fit_diagnostics.mat");

writetable(analysis.reliability.componentSummary, reliabilityFile);
writetable(analysis.diagnosticErrors, errorFile);

summary = table( ...
    string(analysis.modelName), string(analysis.reliability.status), ...
    analysis.reliability.flagCount, ...
    analysis.reliability.availableComponentCount, ...
    analysis.reliability.missingComponentCount, ...
    height(analysis.diagnosticErrors), ...
    'VariableNames', {'ModelName','ReliabilityStatus','FlagCount', ...
    'AvailableComponentCount','MissingComponentCount','DiagnosticErrorCount'});
writetable(summary, summaryFile);
save(dataFile, "analysis");

figureHandle = mechanics.plotting.plotFitReliability(analysis.reliability);
figureCleanup = onCleanup(@() delete(figureHandle)); %#ok<NASGU>
figureFile = mechanics.plotting.exportFigureFiles( ...
    figureHandle, outputFolder, "fit_reliability", "png", 200);
figureFigFile = fullfile(outputFolder, "fit_reliability.fig");

files.reliability = string(reliabilityFile);
files.errors = string(errorFile);
files.summary = string(summaryFile);
files.data = string(dataFile);
files.figure = string(figureFile);
files.figureFig = string(figureFigFile);
end