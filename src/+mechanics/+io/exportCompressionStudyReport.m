function files = exportCompressionStudyReport(study, config)
%EXPORTCOMPRESSIONSTUDYREPORT Export compression figures and Markdown report.
arguments
    study (1,1) struct
    config (1,1) struct = mechanics.config.compressionStudyReportConfig()
end

folder = string(config.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end
figureFiles = mechanics.plotting.exportCompressionStudyFigures(study, config);
reportFile = fullfile(folder, string(config.reportFilename));
fileId = fopen(reportFile, "w");
if fileId < 0
    error("mechanics:io:CompressionReportFileOpenFailed", ...
        "Could not open report file: %s", reportFile);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>

if isfield(study, "analysis") && isfield(study.analysis, "records")
    figureFiles = localWritePopulationReport( ...
        fileId, study, config, figureFiles);
else
    localWriteSpecimenReport(fileId, study, figureFiles);
end

files = figureFiles;
files.report = string(reportFile);
end

function figureFiles = localWritePopulationReport( ...
        fileId, study, config, figureFiles)
titleText = localStudyTitle(study, config);
summary = study.analysis.summary;
status = string(summary.Status);
units = mechanics.plotting.resolveStudyUnits(study.analysis.records);
units.strain = localDisplayStrainUnit(units.strain);
[strainName, stressName] = localMeasureNames(study);

fprintf(fileId, "# %s\n\n", char(titleText));
fprintf(fileId, "Generated: %s\n\n", char(string(study.createdAt)));
fprintf(fileId, "Source file: `%s`\n\n", char(string(study.sourceFile)));

fprintf(fileId, "## Study summary\n\n");
fprintf(fileId, "| Metric | Value |\n|---|---:|\n");
fprintf(fileId, "| Extracted specimens | %d |\n", height(summary));
fprintf(fileId, "| Excluded | %d |\n", nnz(status == "skipped"));
fprintf(fileId, "| Processed | %d |\n", nnz(status == "processed"));
fprintf(fileId, "| Failed | %d |\n", nnz(status == "failed"));
fprintf(fileId, "| Population status | %s |\n\n", char(study.populationStatus));

if isfield(study, "exclusion") && study.exclusion.count > 0
    fprintf(fileId, "## Excluded specimens\n\n");
    fprintf(fileId, "Reason: %s\n\n", char(study.exclusion.reason));
    fprintf(fileId, "| Extraction index | Specimen | Sheet |\n|---:|---|---|\n");
    for index = 1:study.exclusion.count
        fprintf(fileId, "| %d | %s | %s |\n", ...
            study.exclusion.indices(index), ...
            char(study.exclusion.specimenIds(index)), ...
            char(study.exclusion.sheetNames(index)));
    end
    fprintf(fileId, "\n");
end

fprintf(fileId, "## Specimen status\n\n");
fprintf(fileId, ...
    "| Specimen | Status | Maximum %s (%s) | Maximum %s (%s) | Median tangent modulus (%s) | Selected model |\n", ...
    char(strainName), char(units.strain), char(stressName), ...
    char(units.stress), char(units.stress));
fprintf(fileId, "|---|---|---:|---:|---:|---|\n");
for row = 1:height(summary)
    fprintf(fileId, "| %s | %s | %.6g | %.6g | %.6g | %s |\n", ...
        char(summary.SpecimenId(row)), char(summary.Status(row)), ...
        summary.MaximumStrain(row), summary.MaximumStress(row), ...
        summary.MedianTangentModulus(row), char(summary.SelectedModel(row)));
end
fprintf(fileId, "\n");

if study.populationStatus == "completed"
    fprintf(fileId, "## Population analysis\n\n");
    fprintf(fileId, "- Retained specimen count: %d\n", study.population.specimenCount);
    fprintf(fileId, "- Central statistic: `%s`\n", ...
        char(string(study.population.curves.centralStatistic)));
    fprintf(fileId, "- Tangent-modulus population status: `%s`\n\n", ...
        char(string(study.population.tangentModulusStatus)));

    modelParameters = study.population.modelParameters;
    if isfield(modelParameters, "summary") && ~isempty(modelParameters.summary)
        fprintf(fileId, "### Selected-model parameter summary\n\n");
        parameterSummary = modelParameters.summary;
        parameterSummary.Unit = repmat(units.stress, height(parameterSummary), 1);
        localWriteTable(fileId, parameterSummary);
    end
end

audit = mechanics.workflow.summarizeFittingAudit(study);
mechanics.io.writeFittingAuditSection( ...
    fileId, audit, units.strain, units.stress);
if string(audit.status) == "completed"
    auditFigure = mechanics.plotting.plotFittingAudit( ...
        audit, titleText, units.stress);
    if isgraphics(auditFigure)
        figureFiles.fittingAudit = mechanics.plotting.exportFigureFiles( ...
            auditFigure, string(config.outputFolder), "fitting_audit", ...
            string(config.figureFormat), config.figureResolution);
        if config.closeFiguresAfterExport
            close(auditFigure);
        end
    end
end

localWriteFigures(fileId, figureFiles);

fprintf(fileId, "## Reproducibility\n\n");
if isfield(study, "provenance")
    fprintf(fileId, "- MATLAB release: `%s`\n", ...
        char(string(study.provenance.matlabRelease)));
    fprintf(fileId, "- Platform: `%s`\n", char(string(study.provenance.platform)));
    fprintf(fileId, "- Input type: `%s`\n", char(string(study.provenance.inputType)));
end
fprintf(fileId, "- Strain measure: `%s` (`%s`)\n", char(strainName), char(units.strain));
fprintf(fileId, "- Stress measure: `%s` (`%s`)\n", char(stressName), char(units.stress));
fprintf(fileId, "- Configuration is stored in `study.config`.\n");
fprintf(fileId, "- Processed compression variables retain physical negative signs; report figures use positive magnitudes.\n");
fprintf(fileId, "- The maintained Method A workflow uses the last complete loading cycle and first-sample zeroing.\n");
end

function localWriteSpecimenReport(fileId, study, figureFiles)
metrics = study.cycleMetrics;
[~, sourceName, sourceExtension] = fileparts(string(study.sourceFile));
strainUnit = localDisplayStrainUnit(metrics.units.strain);
fprintf(fileId, "# Compression study report\n\n");
fprintf(fileId, "Generated: %s\n\n", char(string(study.createdAt)));
fprintf(fileId, "Source file: `%s%s`\n\n", sourceName, sourceExtension);
fprintf(fileId, "## Cycle selection\n\n| Metric | Value |\n|---|---:|\n");
fprintf(fileId, "| Detected complete cycles | %d |\n", study.cycle.cycleCount);
fprintf(fileId, "| Selected cycle | %d |\n", study.cycle.selectedCycleIndex);
fprintf(fileId, "| Selected branch | %s |\n", char(study.cycle.branch));
fprintf(fileId, "| Loading direction | %s |\n\n", char(study.cycle.loadingDirection));
fprintf(fileId, "## Mechanical metrics\n\n| Metric | Value | Unit |\n|---|---:|---|\n");
fprintf(fileId, "| Peak force | %.6g | %s |\n", metrics.peakForce, metrics.units.force);
fprintf(fileId, "| Peak displacement | %.6g | %s |\n", metrics.peakDisplacement, metrics.units.displacement);
fprintf(fileId, "| Peak stress | %.6g | %s |\n", metrics.peakStress, metrics.units.stress);
fprintf(fileId, "| Peak strain | %.6g | %s |\n", metrics.peakStrain, strainUnit);
fprintf(fileId, "| Loading energy | %.6g | %s |\n", metrics.loadingEnergy, metrics.units.energy);
fprintf(fileId, "| Recovered energy | %.6g | %s |\n", metrics.recoveredEnergy, metrics.units.energy);
fprintf(fileId, "| Hysteresis energy | %.6g | %s |\n", metrics.hysteresisEnergy, metrics.units.energy);
fprintf(fileId, "| Hysteresis fraction | %.6g | - |\n", metrics.hysteresisFraction);
fprintf(fileId, "| Median tangent modulus | %.6g | %s |\n\n", ...
    study.specimen.analysis.tangentModulus.medianModulus, metrics.units.stress);
localWriteFigures(fileId, figureFiles);
fprintf(fileId, "## Interpretation limits\n\n");
fprintf(fileId, "- Metrics refer to the configured selected cycle.\n");
fprintf(fileId, "- Hysteresis is computed from force-displacement work over the selected full cycle.\n");
fprintf(fileId, "- Instrument polarity is normalized to the maintained physical compression sign contract.\n");
end

function localWriteFigures(fileId, figureFiles)
fields = fieldnames(figureFiles);
if isempty(fields)
    return;
end
fprintf(fileId, "## Figures\n\n");
for index = 1:numel(fields)
    path = string(figureFiles.(fields{index}));
    [~, name, extension] = fileparts(path);
    label = string(regexprep(fields{index}, "([a-z])([A-Z])", "$1 $2"));
    label = upper(extractBefore(label, 2)) + extractAfter(label, 1);
    label = replace(label, "Zero reference", "Zero-reference");
    label = replace(label, "Fitting audit", "Constitutive fitting audit");
    fprintf(fileId, "### %s\n\n![%s](%s%s)\n\n", ...
        char(label), char(label), name, extension);
end
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

function [strainName, stressName] = localMeasureNames(study)
strainName = "engineering strain";
stressName = "engineering stress";
if ~isfield(study, "config") || ~isfield(study.config, "specimen") || ...
        ~isfield(study.config.specimen, "processing") || ...
        ~isfield(study.config.specimen.processing, "mechanics")
    return;
end
mechanicsConfig = study.config.specimen.processing.mechanics;
if isfield(mechanicsConfig, "strainMeasure")
    strainName = lower(string(mechanicsConfig.strainMeasure)) + " strain";
end
if isfield(mechanicsConfig, "stressMeasure")
    stressName = lower(string(mechanicsConfig.stressMeasure)) + " stress";
end
end

function unit = localDisplayStrainUnit(unit)
unit = string(unit);
if unit == "-" || unit == "1" || strlength(unit) == 0
    unit = "mm/mm";
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
    filename = "Compression study";
end
titleText = filename + " - compression study report";
end
