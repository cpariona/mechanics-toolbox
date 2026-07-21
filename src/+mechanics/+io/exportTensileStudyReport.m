function outputFiles = exportTensileStudyReport(study, config)
%EXPORTTENSILESTUDYREPORT Export standard figures and a Markdown report.
arguments
    study (1,1) struct
    config (1,1) struct = mechanics.config.studyReportConfig()
end

folder = string(config.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end

figureFiles = mechanics.plotting.exportTensileStudyFigures( ...
    study, config);

reportFile = fullfile(folder, string(config.reportFilename));
fileId = fopen(reportFile, "w");
if fileId < 0
    error("mechanics:io:ReportFileOpenFailed", ...
        "Could not open report file: %s", reportFile);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>

studySummary = mechanics.workflow.summarizeTensileStudy(study);

fprintf(fileId, "# Tensile study report\n\n");
fprintf(fileId, "Generated: %s\n\n", ...
    char(string(study.createdAt)));
fprintf(fileId, "Source file: `%s`\n\n", ...
    char(string(study.sourceFile)));

fprintf(fileId, "## Study summary\n\n");
fprintf(fileId, "| Metric | Value |\n");
fprintf(fileId, "|---|---:|\n");
fprintf(fileId, "| Specimens | %d |\n", ...
    studySummary.SpecimenCount);
fprintf(fileId, "| Processed | %d |\n", ...
    studySummary.ProcessedSpecimenCount);
fprintf(fileId, "| Quality failed | %d |\n", ...
    studySummary.QualityFailedSpecimenCount);
fprintf(fileId, "| Processing failed | %d |\n", ...
    studySummary.FailedSpecimenCount);
fprintf(fileId, "| Fracture detected | %g |\n", ...
    studySummary.FractureDetectedCount);
fprintf(fileId, "| Complete fracture | %g |\n", ...
    studySummary.CompleteFractureCount);
fprintf(fileId, "| Population status | %s |\n\n", ...
    char(studySummary.PopulationStatus));

fprintf(fileId, "## Specimen status\n\n");
fprintf(fileId, "| Specimen | Status | Peak force | Peak displacement | Best model |\n");
fprintf(fileId, "|---|---|---:|---:|---|\n");
summary = study.analysis.summary;
for row = 1:height(summary)
    fprintf(fileId, "| %s | %s | %.6g | %.6g | %s |\n", ...
        char(summary.SpecimenId(row)), ...
        char(summary.Status(row)), ...
        summary.PeakForce(row), ...
        summary.PeakDisplacement(row), ...
        char(summary.BestModel(row)));
end
fprintf(fileId, "\n");

fields = fieldnames(figureFiles);
if ~isempty(fields)
    fprintf(fileId, "## Figures\n\n");
    for index = 1:numel(fields)
        figurePath = string(figureFiles.(fields{index}));
        [~, name, extension] = fileparts(figurePath);
        relativeName = string(name) + string(extension);
        titleText = regexprep(fields{index}, "([a-z])([A-Z])", "$1 $2");
        fprintf(fileId, "### %s\n\n", titleText);
        fprintf(fileId, "![%s](%s)\n\n", ...
            titleText, char(relativeName));
    end
end

fprintf(fileId, "## Reproducibility\n\n");
fprintf(fileId, "- MATLAB release: `%s`\n", ...
    char(study.provenance.matlabRelease));
fprintf(fileId, "- Platform: `%s`\n", ...
    char(study.provenance.platform));
fprintf(fileId, "- Source bytes: `%d`\n", ...
    study.provenance.sourceFileBytes);

outputFiles = figureFiles;
outputFiles.report = string(reportFile);
end
