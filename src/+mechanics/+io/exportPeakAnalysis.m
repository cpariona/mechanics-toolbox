function outputFiles = exportPeakAnalysis(analysis, outputFolder)
%EXPORTPEAKANALYSIS Export peak summary and full analysis.
arguments
    analysis (1,1) struct
    outputFolder (1,1) string
end

if ~isfield(analysis, "peakSummary") || ~istable(analysis.peakSummary)
    error("mechanics:io:MissingPeakSummary", ...
        "Analysis must contain peakSummary.");
end
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
summaryFile = fullfile(outputFolder, "peak_summary.csv");
analysisFile = fullfile(outputFolder, "peak_analysis.mat");
writetable(analysis.peakSummary, summaryFile);
save(analysisFile, "analysis");
outputFiles.summary = string(summaryFile);
outputFiles.analysis = string(analysisFile);
end
