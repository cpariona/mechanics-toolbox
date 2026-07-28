function outputFiles = exportCompressionStudy(study, exportConfig)
%EXPORTCOMPRESSIONSTUDY Export a complete compression-study bundle.
arguments
    study (1,1) struct
    exportConfig (1,1) struct
end

folder = string(exportConfig.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end

outputFiles = struct();

if exportConfig.saveStudyMat
    studyFile = fullfile(folder, "compression_study.mat");
    save(studyFile, "study");
    outputFiles.study = string(studyFile);
end

if exportConfig.saveManifest
    manifestFile = fullfile(folder, "compression_manifest.csv");
    writetable(study.manifest, manifestFile);
    outputFiles.manifest = string(manifestFile);
end

if exportConfig.saveSummary
    summaryFile = fullfile(folder, "compression_summary.csv");
    writetable(study.analysis.summary, summaryFile);
    outputFiles.summary = string(summaryFile);
end

if exportConfig.savePopulation && study.populationStatus == "completed"
    outputFiles.population = mechanics.io.exportPopulationAnalysis( ...
        study.population, folder);
end
end