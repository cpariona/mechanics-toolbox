function outputFiles = exportFitWindowStability(stability, outputFolder)
%EXPORTFITWINDOWSTABILITY Export fit-window stability tables and MAT data.
arguments
    stability (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

windowFile = fullfile(outputFolder, "fit_window_summary.csv");
parameterFile = fullfile(outputFolder, "fit_window_parameters.csv");
dataFile = fullfile(outputFolder, "fit_window_stability.mat");

writetable(stability.windowSummary, windowFile);
writetable(stability.parameterSummary, parameterFile);
save(dataFile, "stability");

outputFiles.windows = string(windowFile);
outputFiles.parameters = string(parameterFile);
outputFiles.data = string(dataFile);
end
