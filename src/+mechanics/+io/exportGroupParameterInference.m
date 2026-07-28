function files = exportGroupParameterInference(inference, outputFolder)
%EXPORTGROUPPARAMETERINFERENCE Export pairwise parameter comparisons.
arguments
    inference (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

comparisonFile = fullfile(outputFolder, "group_parameter_comparisons.csv");
summaryFile = fullfile(outputFolder, "group_parameter_inference_summary.csv");
dataFile = fullfile(outputFolder, "group_parameter_inference.mat");

writetable(inference.comparisonTable, comparisonFile);
summary = table( ...
    inference.comparisonCount, ...
    inference.successfulComparisonCount, ...
    inference.significantComparisonCount, ...
    'VariableNames', {'ComparisonCount','SuccessfulComparisonCount', ...
    'SignificantComparisonCount'});
writetable(summary, summaryFile);
save(dataFile, "inference");

figureHandle = mechanics.plotting.plotGroupParameterInference(inference);
figureCleanup = onCleanup(@() delete(figureHandle)); %#ok<NASGU>
figureFile = mechanics.plotting.exportFigureFiles( ...
    figureHandle, outputFolder, "group_parameter_inference", "png", 200);
figureFigFile = fullfile(outputFolder, "group_parameter_inference.fig");

files.comparisons = string(comparisonFile);
files.summary = string(summaryFile);
files.data = string(dataFile);
files.figure = string(figureFile);
files.figureFig = string(figureFigFile);
end