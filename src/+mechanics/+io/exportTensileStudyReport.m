function outputFiles = exportTensileStudyReport(study, config)
%EXPORTTENSILESTUDYREPORT Export standard figures and a Markdown report.
arguments
    study (1,1) struct
    config (1,1) struct = mechanics.config.tensileStudyReportConfig()
end

if strlength(strtrim(string(config.studyTitle))) == 0
    config.studyTitle = "auto";
end

folder = string(config.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end

figureFiles = mechanics.plotting.exportTensileStudyFigures(study, config);
reportFile = fullfile(folder, string(config.reportFilename));
fileId = fopen(reportFile, "w");
if fileId < 0
    error("mechanics:io:ReportFileOpenFailed", ...
        "Could not open report file: %s", reportFile);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>

studySummary = mechanics.workflow.summarizeTensileStudy(study);
titleText = localStudyTitle(study, config);

fprintf(fileId, "# %s\n\n", char(titleText));
fprintf(fileId, "Generated: %s\n\n", char(string(study.createdAt)));
fprintf(fileId, "Source file: `%s`\n\n", char(string(study.sourceFile)));

fprintf(fileId, "## Study summary\n\n");
fprintf(fileId, "| Metric | Value |\n");
fprintf(fileId, "|---|---:|\n");
fprintf(fileId, "| Extracted specimens | %d |\n", ...
    studySummary.SpecimenCount + studySummary.ExcludedSpecimenCount);
fprintf(fileId, "| Excluded | %d |\n", studySummary.ExcludedSpecimenCount);
fprintf(fileId, "| Processed | %d |\n", studySummary.ProcessedSpecimenCount);
fprintf(fileId, "| Quality failed | %d |\n", ...
    studySummary.QualityFailedSpecimenCount);
fprintf(fileId, "| Processing failed | %d |\n", ...
    studySummary.FailedSpecimenCount);
fprintf(fileId, "| Peak metrics available | %d |\n", ...
    studySummary.PeakMetricSpecimenCount);
fprintf(fileId, "| Population status | %s |\n\n", ...
    char(studySummary.PopulationStatus));

if isfield(study, "exclusion") && study.exclusion.count > 0
    fprintf(fileId, "## Excluded specimens\n\n");
    fprintf(fileId, "Reason: %s\n\n", char(study.exclusion.reason));
    fprintf(fileId, "| Extraction index | Specimen | Sheet |\n");
    fprintf(fileId, "|---:|---|---|\n");
    for index = 1:study.exclusion.count
        fprintf(fileId, "| %d | %s | %s |\n", ...
            study.exclusion.indices(index), ...
            char(study.exclusion.specimenIds(index)), ...
            char(study.exclusion.sheetNames(index)));
    end
    fprintf(fileId, "\n");
end

fprintf(fileId, "## Specimen status\n\n");
fprintf(fileId, ["| Specimen | Status | Maximum strain | Maximum stress | " ...
    "Peak force | Median tangent modulus | Selected model |\n"]);
fprintf(fileId, "|---|---|---:|---:|---:|---:|---|\n");
summary = study.analysis.summary;
for row = 1:height(summary)
    fprintf(fileId, "| %s | %s | %.6g | %.6g | %.6g | %.6g | %s |\n", ...
        char(summary.SpecimenId(row)), char(summary.Status(row)), ...
        summary.MaximumStrain(row), summary.MaximumStress(row), ...
        summary.PeakForce(row), summary.MedianTangentModulus(row), ...
        char(summary.BestModel(row)));
end
fprintf(fileId, "\n");

if string(study.populationStatus) == "completed" && ...
        isfield(study, "population")
    fprintf(fileId, "## Population analysis\n\n");
    if isfield(study.population, "specimenCount")
        fprintf(fileId, "- Retained specimen count: %d\n", ...
            study.population.specimenCount);
    end
    if isfield(study.population, "curves") && ...
            isfield(study.population.curves, "centralStatistic")
        fprintf(fileId, "- Central statistic: `%s`\n", ...
            char(string(study.population.curves.centralStatistic)));
    end
    if isfield(study.population, "tangentModulusStatus")
        fprintf(fileId, "- Tangent-modulus population status: `%s`\n", ...
            char(string(study.population.tangentModulusStatus)));
    end
    fprintf(fileId, "\n");

    if isfield(study.population, "modelParameters") && ...
            isfield(study.population.modelParameters, "summary") && ...
            ~isempty(study.population.modelParameters.summary)
        fprintf(fileId, "### Selected-model parameter summary\n\n");
        localWriteTable(fileId, study.population.modelParameters.summary);
    end
end

fields = fieldnames(figureFiles);
if ~isempty(fields)
    fprintf(fileId, "## Figures\n\n");
    for index = 1:numel(fields)
        figurePath = string(figureFiles.(fields{index}));
        [~, name, extension] = fileparts(figurePath);
        relativeName = string(name) + string(extension);
        figureTitle = regexprep(fields{index}, "([a-z])([A-Z])", "$1 $2");
        fprintf(fileId, "### %s\n\n", figureTitle);
        fprintf(fileId, "![%s](%s)\n\n", ...
            figureTitle, char(relativeName));
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

function localWriteTable(fileId, inputTable)
names = string(inputTable.Properties.VariableNames);
fprintf(fileId, "| %s |\n", char(strjoin(names, " | ")));
fprintf(fileId, "|%s|\n", char(strjoin(repmat("---", size(names)), "|")));
for row = 1:height(inputTable)
    values = strings(1, width(inputTable));
    for column = 1:width(inputTable)
        value = inputTable{row, column};
        if isnumeric(value) || islogical(value)
            values(column) = string(value);
        else
            values(column) = string(inputTable.(names(column))(row));
        end
    end
    fprintf(fileId, "| %s |\n", char(strjoin(values, " | ")));
end
fprintf(fileId, "\n");
end

function titleText = localStudyTitle(study, config)
if string(config.studyTitle) ~= "auto"
    titleText = string(config.studyTitle);
    return;
end
[~, filename] = fileparts(string(study.sourceFile));
filename = replace(filename, ["_", "-"], " ");
if strlength(filename) == 0
    filename = "Tensile study";
end
titleText = filename + " — tensile study report";
end
