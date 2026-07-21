function outputFiles = exportFitReliability(assessment, outputFolder)
%EXPORTFITRELIABILITY Export integrated fit reliability assessment.
arguments
    assessment (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

componentFile = fullfile(outputFolder, "fit_reliability_components.csv");
summaryFile = fullfile(outputFolder, "fit_reliability_summary.csv");
dataFile = fullfile(outputFolder, "fit_reliability.mat");

writetable(assessment.componentSummary, componentFile);
summary = table(assessment.modelName, assessment.status, ...
    assessment.flagCount, assessment.availableComponentCount, ...
    assessment.missingComponentCount, ...
    'VariableNames', {'Model','Status','FlagCount', ...
    'AvailableComponentCount','MissingComponentCount'});
writetable(summary, summaryFile);
save(dataFile, "assessment");

outputFiles.components = string(componentFile);
outputFiles.summary = string(summaryFile);
outputFiles.data = string(dataFile);
end
