function saveProcessedExperiment(experiment, processedFolder, baseFileName)
% Saves processed experiment data and a summary table.
%
% Inputs:
%   experiment      - Structure containing processed mechanical data.
%   processedFolder - Folder where processed files are saved.
%   baseFileName    - Base file name without extension.
%
% Outputs:
%   Saves .mat and .csv files.

    ensureFolderExists(processedFolder);

    save(fullfile(processedFolder, [baseFileName '.mat']), ...
        'experiment');

    summaryTable = buildMechanicalSummaryTable(experiment);

    writetable(summaryTable, ...
        fullfile(processedFolder, [baseFileName '_summary.csv']));
end