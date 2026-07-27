function files = exportStudyConsensusModel(consensus, outputFolder)
%EXPORTSTUDYCONSENSUSMODEL Export study consensus model results.
arguments
    consensus (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

metricFile = fullfile(outputFolder,'consensus_model_metrics.csv');
parameterFile = fullfile(outputFolder,'consensus_model_parameters.csv');
parameterSummaryFile = fullfile(outputFolder,'consensus_model_parameter_summary.csv');
dataFile = fullfile(outputFolder,'consensus_model.mat');

writetable(consensus.metricSummary, metricFile);
writetable(consensus.parameterTable, parameterFile);
writetable(consensus.parameterSummary, parameterSummaryFile);

figureHandle = mechanics.plotting.plotStudyConsensusModel(consensus);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
figureFile = mechanics.plotting.exportFigureFiles( ...
    figureHandle, outputFolder, "consensus_model", "png", 200);
figureFigFile = fullfile(outputFolder,'consensus_model.fig');
save(dataFile,'consensus');

files.metrics = string(metricFile);
files.parameters = string(parameterFile);
files.parameterSummary = string(parameterSummaryFile);
files.figure = string(figureFile);
files.figureFig = string(figureFigFile);
files.data = string(dataFile);
end