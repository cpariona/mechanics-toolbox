function files = exportCompressionStudy(study, config)
%EXPORTCOMPRESSIONSTUDY Export compression tables, MAT data, and report.
arguments
    study (1,1) struct
    config (1,1) struct
end

folder = string(config.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end
files = struct();

if config.saveProcessedTable
    specimen = study.specimen;
    tableData = table( ...
        specimen.processed.displacement, ...
        specimen.processed.force, ...
        specimen.processed.strain, ...
        specimen.processed.stress, ...
        specimen.analysis.tangentModulus.tangentModulus, ...
        'VariableNames', { ...
        'Displacement','Force','Strain','Stress','TangentModulus'});
    files.processed = fullfile(folder, "compression_processed.csv");
    writetable(tableData, files.processed);
end

if config.saveCycleMetrics
    metrics = study.cycleMetrics;
    files.metrics = fullfile(folder, "compression_cycle_metrics.csv");
    metricsTable = struct2table(rmfield(metrics, "units"), "AsArray", true);
    writetable(metricsTable, files.metrics);
end

if config.saveStudyMat
    files.study = fullfile(folder, "compression_study.mat");
    save(files.study, "study");
end

reportConfig = config.report;
reportConfig.outputFolder = fullfile(folder, "report");
reportFiles = mechanics.io.exportCompressionStudyReport(study, reportConfig);
reportNames = fieldnames(reportFiles);
for index = 1:numel(reportNames)
    sourceName = string(reportNames{index});
    targetName = "report" + upper(extractBetween(sourceName,1,1)) + ...
        extractAfter(sourceName,1);
    files.(char(targetName)) = reportFiles.(reportNames{index});
end

names = fieldnames(files);
for index = 1:numel(names)
    files.(names{index}) = string(files.(names{index}));
end
end