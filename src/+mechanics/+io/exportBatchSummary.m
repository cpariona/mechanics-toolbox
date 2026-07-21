function outputFiles = exportBatchSummary(batch, outputFolder)
%EXPORTBATCHSUMMARY Export batch summary and complete MATLAB result.
arguments
    batch (1,1) struct
    outputFolder (1,1) string
end

if ~isfield(batch, "summary") || ~istable(batch.summary)
    error("mechanics:io:InvalidBatch", ...
        "Batch must contain a summary table.");
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

summaryFile = fullfile(outputFolder, "batch_summary.csv");
batchFile = fullfile(outputFolder, "batch_results.mat");

writetable(batch.summary, summaryFile);
save(batchFile, "batch");

outputFiles.summary = string(summaryFile);
outputFiles.batch = string(batchFile);
end
