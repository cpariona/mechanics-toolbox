function files = exportBatchModelComparison(batch, outputFolder)
%EXPORTBATCHMODELCOMPARISON Export specimen and aggregate summaries.
arguments
    batch (1,1) struct
    outputFolder (1,1) string
end
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
specimenFile = fullfile(outputFolder, 'batch_specimen_summary.csv');
modelFile = fullfile(outputFolder, 'batch_model_summary.csv');
groupFile = fullfile(outputFolder, 'batch_group_summary.csv');
dataFile = fullfile(outputFolder, 'batch_model_comparison.mat');
writetable(batch.specimenSummary, specimenFile);
writetable(batch.modelSummary, modelFile);
writetable(batch.groupSummary, groupFile);
save(dataFile, 'batch');
files.specimens = string(specimenFile);
files.models = string(modelFile);
files.groups = string(groupFile);
files.data = string(dataFile);
end
