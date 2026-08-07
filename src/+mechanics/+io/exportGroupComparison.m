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

if isfield(result, "modelInitialShearSummary") && ...
        ~isempty(result.modelInitialShearSummary)
    shearFile = fullfile(outputFolder, "group_model_initial_shear_modulus.csv");
    writetable(result.modelInitialShearSummary, shearFile);
    outputFiles.modelInitialShearSummary = string(shearFile);
end

if isfield(result, "curveComparison") && ...
        ~isempty(fieldnames(result.curveComparison))
    comparison = result.curveComparison;
    curveTable = table( ...
        comparison.strain, ...
        comparison.meanStressA, ...
        comparison.confidenceLowerA, ...
        comparison.confidenceUpperA, ...
        comparison.meanStressB, ...
        comparison.confidenceLowerB, ...
        comparison.confidenceUpperB, ...
        comparison.meanDifference, ...
        comparison.confidenceLower, ...
        comparison.confidenceUpper, ...
        'VariableNames', {'Strain', ...
        'MeanStressA','ConfidenceLowerA','ConfidenceUpperA', ...
        'MeanStressB','ConfidenceLowerB','ConfidenceUpperB', ...
        'MeanDifference','ConfidenceLower','ConfidenceUpper'});
    curveFile = fullfile(outputFolder, "pairwise_curve_comparison.csv");
    metricFile = fullfile(outputFolder, "pairwise_metric_comparison.csv");
    writetable(curveTable, curveFile);
    writetable(result.metricComparison, metricFile);
    outputFiles.curveComparison = string(curveFile);
    outputFiles.metricComparison = string(metricFile);

    [outputFiles.figure, outputFiles.figureFig] = localExportFigure( ...
        mechanics.plotting.plotGroupComparison(result), ...
        outputFolder, "group_comparison");

    [outputFiles.metricFigure, outputFiles.metricFigureFig] = ...
        localExportFigure( ...
        mechanics.plotting.plotGroupMetricComparison(result), ...
        outputFolder, "group_metric_comparison");

    if localHasTangentModulusComparison(result)
        [outputFiles.tangentModulusFigure, ...
            outputFiles.tangentModulusFigureFig] = localExportFigure( ...
            mechanics.plotting.plotGroupTangentModulusComparison(result), ...
            outputFolder, "group_tangent_modulus_comparison");
    end
end

matFile = fullfile(outputFolder, "group_comparison.mat");
save(matFile, "result");
outputFiles.comparison = string(matFile);

outputFiles.report = mechanics.io.exportGroupComparisonReport( ...
    result, outputFiles, outputFolder);
end

function available = localHasTangentModulusComparison(result)
available = numel(result.groups) == 2;
if ~available
    return;
end
for index = 1:2
    population = result.groups(index).population;
    available = available && ...
        isfield(population, "tangentModulusStatus") && ...
        population.tangentModulusStatus == "completed";
end
end

function [pngFile, figFile] = localExportFigure(figureHandle, outputFolder, baseName)
cleanup = onCleanup(@() delete(figureHandle)); %#ok<NASGU>
pngFile = string(mechanics.plotting.exportFigureFiles( ...
    figureHandle, outputFolder, baseName, "png", 200));
figFile = string(fullfile(outputFolder, baseName + ".fig"));
end
