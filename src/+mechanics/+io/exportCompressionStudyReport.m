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

metrics = study.cycleMetrics;
[~, sourceName, sourceExtension] = fileparts(string(study.sourceFile));
fprintf(fileId, "# Compression study report\n\n");
fprintf(fileId, "Generated: %s\n\n", char(string(study.createdAt)));
fprintf(fileId, "Source file: `%s%s`\n\n", sourceName, sourceExtension);

fprintf(fileId, "## Cycle selection\n\n");
fprintf(fileId, "| Metric | Value |\n|---|---:|\n");
fprintf(fileId, "| Detected complete cycles | %d |\n", study.cycle.cycleCount);
fprintf(fileId, "| Selected cycle | %d |\n", study.cycle.selectedCycleIndex);
fprintf(fileId, "| Selected branch | %s |\n", char(study.cycle.branch));
fprintf(fileId, "| Loading direction | %s |\n\n", char(study.cycle.loadingDirection));

fprintf(fileId, "## Mechanical metrics\n\n");
fprintf(fileId, "| Metric | Value | Unit |\n|---|---:|---|\n");
fprintf(fileId, "| Peak force | %.6g | %s |\n", metrics.peakForce, metrics.units.force);
fprintf(fileId, "| Peak displacement | %.6g | %s |\n", metrics.peakDisplacement, metrics.units.displacement);
fprintf(fileId, "| Peak stress | %.6g | %s |\n", metrics.peakStress, metrics.units.stress);
fprintf(fileId, "| Peak strain | %.6g | %s |\n", metrics.peakStrain, metrics.units.strain);
fprintf(fileId, "| Loading energy | %.6g | %s |\n", metrics.loadingEnergy, metrics.units.energy);
fprintf(fileId, "| Recovered energy | %.6g | %s |\n", metrics.recoveredEnergy, metrics.units.energy);
fprintf(fileId, "| Hysteresis energy | %.6g | %s |\n", metrics.hysteresisEnergy, metrics.units.energy);
fprintf(fileId, "| Hysteresis fraction | %.6g | - |\n", metrics.hysteresisFraction);
fprintf(fileId, "| Median tangent modulus | %.6g | %s |\n\n", ...
    study.specimen.analysis.tangentModulus.medianModulus, metrics.units.stress);

fields = fieldnames(figureFiles);
if ~isempty(fields)
    fprintf(fileId, "## Figures\n\n");
    for index = 1:numel(fields)
        path = string(figureFiles.(fields{index}));
        [~, name, extension] = fileparts(path);
        label = regexprep(fields{index}, "([a-z])([A-Z])", "$1 $2");
        fprintf(fileId, "### %s\n\n", label);
        fprintf(fileId, "![%s](%s%s)\n\n", label, name, extension);
    end
end

fprintf(fileId, "## Interpretation limits\n\n");
fprintf(fileId, "- Metrics refer to the configured selected cycle.\n");
fprintf(fileId, "- Hysteresis is computed from force-displacement work over the selected full cycle.\n");
fprintf(fileId, "- Contact detection and sign convention remain configuration-dependent.\n");

files = figureFiles;
files.report = string(reportFile);
end