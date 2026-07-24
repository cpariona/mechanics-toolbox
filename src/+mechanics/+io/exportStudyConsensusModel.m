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
figureFile = fullfile(outputFolder,'consensus_model.png');
dataFile = fullfile(outputFolder,'consensus_model.mat');

writetable(consensus.metricSummary, metricFile);
writetable(consensus.parameterTable, parameterFile);
writetable(consensus.parameterSummary, parameterSummaryFile);

figureHandle = mechanics.plotting.plotStudyConsensusModel(consensus);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
exportgraphics(figureHandle, figureFile, 'Resolution', 200);
save(dataFile,'consensus');

files.metrics = string(metricFile);
files.parameters = string(parameterFile);
files.parameterSummary = string(parameterSummaryFile);
files.figure = string(figureFile);
files.data = string(dataFile);
end
