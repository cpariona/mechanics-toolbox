function files = exportModelComparison(comparison, outputFolder)
%EXPORTMODELCOMPARISON Export model-comparison summary and full result.
arguments
    comparison (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

summaryFile = fullfile(outputFolder, "model_comparison_summary.csv");
selectionFile = fullfile(outputFolder, "model_selection.csv");
dataFile = fullfile(outputFolder, "model_comparison.mat");

writetable(comparison.summary, summaryFile);
selection = table( ...
    string(comparison.selectionCriterion), ...
    string(comparison.selectedModelName), ...
    logical(comparison.hasSelectedModel), ...
    'VariableNames', {'SelectionCriterion','SelectedModelName', ...
    'HasSelectedModel'});
writetable(selection, selectionFile);
save(dataFile, "comparison");

figureHandle = mechanics.plotting.plotModelComparison(comparison);
figureCleanup = onCleanup(@() delete(figureHandle)); %#ok<NASGU>
figureFile = mechanics.plotting.exportFigureFiles( ...
    figureHandle, outputFolder, "model_comparison", "png", 200);
figureFigFile = fullfile(outputFolder, "model_comparison.fig");

files.summary = string(summaryFile);
files.selection = string(selectionFile);
files.data = string(dataFile);
files.figure = string(figureFile);
files.figureFig = string(figureFigFile);
end