function outputFiles = exportFractureAnalysis(analysis, outputFolder)
%EXPORTFRACTUREANALYSIS Export fracture summary and full analysis.
arguments
    analysis (1,1) struct
    outputFolder (1,1) string
end

if ~isfield(analysis, "fractureSummary") || ...
        ~istable(analysis.fractureSummary)
    error("mechanics:io:MissingFractureSummary", ...
        "Analysis must contain fractureSummary.");
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

summaryFile = fullfile(outputFolder, "fracture_summary.csv");
analysisFile = fullfile(outputFolder, "fracture_analysis.mat");

writetable(analysis.fractureSummary, summaryFile);
save(analysisFile, "analysis");

outputFiles.summary = string(summaryFile);
outputFiles.analysis = string(analysisFile);
end
