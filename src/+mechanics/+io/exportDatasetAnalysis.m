function outputFiles = exportDatasetAnalysis(analysis, outputFolder)
%EXPORTDATASETANALYSIS Export summary and full dataset-analysis result.
arguments
    analysis (1,1) struct
    outputFolder (1,1) string
end

if ~isfield(analysis, "summary") || ~istable(analysis.summary)
    error("mechanics:io:InvalidDatasetAnalysis", ...
        "Analysis must contain a summary table.");
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

summaryFile = fullfile(outputFolder, "dataset_summary.csv");
analysisFile = fullfile(outputFolder, "dataset_analysis.mat");

writetable(analysis.summary, summaryFile);
save(analysisFile, "analysis");

outputFiles.summary = string(summaryFile);
outputFiles.analysis = string(analysisFile);
end
