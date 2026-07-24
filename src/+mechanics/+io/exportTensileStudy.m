function outputFiles = exportTensileStudy(study, exportConfig)
%EXPORTTENSILESTUDY Export a complete tensile-study bundle.
arguments
    study (1,1) struct
    exportConfig (1,1) struct
end

folder = string(exportConfig.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end

outputFiles = struct();

if exportConfig.saveTables
    studySummary = mechanics.workflow.summarizeTensileStudy(study);

    outputFiles.studySummary = fullfile(folder, "study_summary.csv");
    outputFiles.datasetSummary = fullfile(folder, "dataset_summary.csv");
    writetable(studySummary, outputFiles.studySummary);
    writetable(study.analysis.summary, outputFiles.datasetSummary);

    if isfield(study.analysis, "peakSummary")
        outputFiles.peakSummary = fullfile(folder, "peak_summary.csv");
        writetable(study.analysis.peakSummary, outputFiles.peakSummary);
    end

    provenanceTable = struct2table(study.provenance, "AsArray", true);
    outputFiles.provenance = fullfile(folder, "provenance.csv");
    writetable(provenanceTable, outputFiles.provenance);

    if isfield(study.population, "metrics") && ...
            istable(study.population.metrics)
        outputFiles.populationMetrics = ...
            fullfile(folder, "population_metrics.csv");
        writetable(study.population.metrics, ...
            outputFiles.populationMetrics);
    end
end

if exportConfig.saveAnalysisMat
    outputFiles.study = fullfile(folder, "tensile_study.mat");
    save(outputFiles.study, "study");
end

if exportConfig.saveConfigurationMat
    config = study.config; %#ok<NASGU>
    outputFiles.config = fullfile(folder, "study_config.mat");
    save(outputFiles.config, "config");
end

fields = fieldnames(outputFiles);
for index = 1:numel(fields)
    outputFiles.(fields{index}) = string(outputFiles.(fields{index}));
end
end