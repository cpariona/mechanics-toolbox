function outputFiles = exportGroupComparison(result, outputFolder)
%EXPORTGROUPCOMPARISON Export grouped populations and comparisons.
arguments
    result (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

name = strings(numel(result.groups), 1);
count = zeros(numel(result.groups), 1);
for index = 1:numel(result.groups)
    name(index) = result.groups(index).name;
    count(index) = result.groups(index).specimenCount;
    groupFolder = fullfile( ...
        outputFolder, regexprep(name(index), "[^A-Za-z0-9_-]", "_"));
    mechanics.io.exportPopulationAnalysis( ...
        result.groups(index).population, groupFolder);
end

summary = table(name, count, ...
    'VariableNames', {'Group','SpecimenCount'});
summaryFile = fullfile(outputFolder, "group_summary.csv");
writetable(summary, summaryFile);
outputFiles.groupSummary = string(summaryFile);

if isfield(result, "curveComparison") && ...
        ~isempty(fieldnames(result.curveComparison))
    comparison = result.curveComparison;
    curveTable = table( ...
        comparison.strain, comparison.meanStressA, ...
        comparison.meanStressB, comparison.meanDifference, ...
        comparison.confidenceLower, comparison.confidenceUpper, ...
        'VariableNames', {'Strain','MeanStressA','MeanStressB', ...
        'MeanDifference','ConfidenceLower','ConfidenceUpper'});
    curveFile = fullfile(outputFolder, "pairwise_curve_comparison.csv");
    metricFile = fullfile(outputFolder, "pairwise_metric_comparison.csv");
    writetable(curveTable, curveFile);
    writetable(result.metricComparison, metricFile);
    outputFiles.curveComparison = string(curveFile);
    outputFiles.metricComparison = string(metricFile);

    figureHandle = mechanics.plotting.plotGroupComparison(result);
    figureCleanup = onCleanup(@() delete(figureHandle)); %#ok<NASGU>
    figureFile = mechanics.plotting.exportFigureFiles( ...
        figureHandle, outputFolder, "group_comparison", "png", 200);
    outputFiles.figure = string(figureFile);
    outputFiles.figureFig = string( ...
        fullfile(outputFolder, "group_comparison.fig"));
end

matFile = fullfile(outputFolder, "group_comparison.mat");
save(matFile, "result");
outputFiles.comparison = string(matFile);
end