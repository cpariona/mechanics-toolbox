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
units = mechanics.plotting.resolveStudyUnits(study.analysis.records);
mechanicsConfig = localMechanicsConfig(study);
analysisConfig = localAnalysisConfig(study);
fittingConfig = localFittingConfig(study);
strainName = localStrainName(mechanicsConfig);
stressName = localStressName(mechanicsConfig);
strainUnit = "mm/mm";
stressUnit = localUnit(units, "stress", "-");
forceUnit = localUnit(units, "force", "-");

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
header = sprintf([ ...
    '| Specimen | Status | Maximum %s (%s) | Maximum %s (%s) | ' ...
    'Peak force (%s) | Median tangent modulus (%s) | Selected model |\n'], ...
    strainName, strainUnit, stressName, stressUnit, forceUnit, stressUnit);
fprintf(fileId, "%s", header);
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
        parameterSummary = study.population.modelParameters.summary;
        parameterSummary.Unit = repmat(stressUnit, height(parameterSummary), 1);
        localWriteTable(fileId, parameterSummary);
    end
end

audit = mechanics.workflow.summarizeFittingAudit(study);
mechanics.io.writeFittingAuditSection( ...
    fileId, audit, strainUnit, stressUnit);
if string(audit.status) == "completed"
    auditFigure = mechanics.plotting.plotFittingAudit( ...
        audit, titleText, stressUnit);
    if isgraphics(auditFigure)
        figureFiles.fittingAudit = mechanics.plotting.exportFigureFiles( ...
            auditFigure, folder, "fitting_audit", ...
            string(config.figureFormat), config.figureResolution);
        if config.closeFiguresAfterExport
            close(auditFigure);
        end
    end
end

fields = fieldnames(figureFiles);
if ~isempty(fields)
    fprintf(fileId, "## Figures\n\n");
    for index = 1:numel(fields)
        figurePath = string(figureFiles.(fields{index}));
        [~, name, extension] = fileparts(figurePath);
        relativeName = string(name) + string(extension);
        figureTitle = localFigureTitle(fields{index});
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
fprintf(fileId, "- Strain measure: `%s`\n", ...
    char(localField(mechanicsConfig, "strainMeasure", "unspecified")));
fprintf(fileId, "- Strain unit: `%s`\n", char(strainUnit));
fprintf(fileId, "- Stress measure: `%s`\n", ...
    char(localField(mechanicsConfig, "stressMeasure", "unspecified")));
fprintf(fileId, "- Stress unit: `%s`\n", char(stressUnit));
fprintf(fileId, "- Area evolution: `%s`\n", ...
    char(localField(mechanicsConfig, "areaEvolution", "unspecified")));
if isfield(analysisConfig, "summaryStrainRange")
    fprintf(fileId, "- Tangent-modulus summary strain range: `[%g, %g] %s`\n", ...
        analysisConfig.summaryStrainRange(1), ...
        analysisConfig.summaryStrainRange(2), char(strainUnit));
end
if isfield(fittingConfig, "modelNames")
    fprintf(fileId, "- Candidate models: `%s`\n", ...
        char(strjoin(string(fittingConfig.modelNames(:))', ", ")));
end
if isfield(fittingConfig, "selectionConfig") && ...
        isfield(fittingConfig.selectionConfig, "rankingMetric")
    fprintf(fileId, "- Model-ranking metric: `%s`\n", ...
        char(string(fittingConfig.selectionConfig.rankingMetric)));
end
if isfield(fittingConfig, "fitConfig")
    fitConfig = fittingConfig.fitConfig;
    if isfield(fitConfig, "numberOfStarts")
        fprintf(fileId, "- Fit starts: `%d`\n", fitConfig.numberOfStarts);
    end
    if isfield(fitConfig, "randomSeed")
        fprintf(fileId, "- Fit random seed: `%g`\n", fitConfig.randomSeed);
    end
end

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
            values(column) = localTableText(value);
        else
            values(column) = localTableText(inputTable.(names(column))(row));
        end
    end
    fprintf(fileId, "| %s |\n", char(strjoin(values, " | ")));
end
fprintf(fileId, "\n");
end

function text = localTableText(value)
text = string(value);
missingMask = ismissing(text);
text(missingMask) = "";
if ~isscalar(text)
    text = strjoin(text(:)', ", ");
end
end

function config = localMechanicsConfig(study)
config = struct();
if isfield(study, "config") && ...
        isfield(study.config, "datasetAnalysis") && ...
        isfield(study.config.datasetAnalysis, "processingConfig") && ...
        isfield(study.config.datasetAnalysis.processingConfig, "mechanics")
    config = study.config.datasetAnalysis.processingConfig.mechanics;
end
end

function config = localAnalysisConfig(study)
config = struct();
if isfield(study, "config") && ...
        isfield(study.config, "datasetAnalysis") && ...
        isfield(study.config.datasetAnalysis, "processingConfig") && ...
        isfield(study.config.datasetAnalysis.processingConfig, "analysis")
    config = study.config.datasetAnalysis.processingConfig.analysis;
end
end

function config = localFittingConfig(study)
config = struct();
if isfield(study, "config") && ...
        isfield(study.config, "datasetAnalysis") && ...
        isfield(study.config.datasetAnalysis, "fitting")
    config = study.config.datasetAnalysis.fitting;
end
end

function name = localStrainName(config)
measure = lower(localField(config, "strainMeasure", "engineering"));
if measure == "true"
    name = "true strain";
else
    name = "engineering strain";
end
end

function name = localStressName(config)
measure = lower(localField(config, "stressMeasure", "engineering"));
if measure == "true"
    name = "true stress";
else
    name = "engineering stress";
end
end

function value = localField(config, fieldName, defaultValue)
if isfield(config, fieldName)
    value = string(config.(fieldName));
else
    value = string(defaultValue);
end
end

function unit = localUnit(units, fieldName, defaultValue)
if isfield(units, fieldName) && strlength(string(units.(fieldName))) > 0
    unit = string(units.(fieldName));
else
    unit = string(defaultValue);
end
end

function titleText = localFigureTitle(fieldName)
switch string(fieldName)
    case "individualCurves"
        titleText = "Individual curves";
    case "populationCurve"
        titleText = "Population curve";
    case "peakMetrics"
        titleText = "Peak metrics";
    case "tangentModulus"
        titleText = "Tangent modulus";
    case "populationTangentModulus"
        titleText = "Population tangent modulus";
    case "zeroReferenceDiagnostics"
        titleText = "Zero-reference diagnostics";
    case "fittingAudit"
        titleText = "Constitutive fitting audit";
    otherwise
        titleText = regexprep(string(fieldName), "([a-z])([A-Z])", "$1 $2");
        titleText = upper(extractBefore(titleText, 2)) + extractAfter(titleText, 1);
end
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
