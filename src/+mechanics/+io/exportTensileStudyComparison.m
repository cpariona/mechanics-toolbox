function outputFiles = exportTensileStudyComparison(comparison, outputFolder)
%EXPORTTENSILESTUDYCOMPARISON Export a completed tensile-study comparison.
arguments
    comparison (1,1) struct
    outputFolder (1,1) string
end

required = ["testType","groupLabels","studySummaries", ...
    "compatibility","groupComparison"];
if ~all(isfield(comparison, required)) || ...
        lower(string(comparison.testType)) ~= "tension"
    error("mechanics:io:InvalidTensileStudyComparison", ...
        "comparison must be a completed tensile-study comparison result.");
end

folder = string(outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end

studySummaryFile = fullfile(folder, "study_summary.csv");
writetable(comparison.studySummaries, studySummaryFile);
outputFiles.studySummary = string(studySummaryFile);

compatibilityTable = localCompatibilityTable(comparison);
compatibilityFile = fullfile(folder, "study_compatibility.csv");
writetable(compatibilityTable, compatibilityFile);
outputFiles.compatibility = string(compatibilityFile);

groupComparison = comparison.groupComparison;
if isfield(groupComparison, "metricComparison") && ...
        ~isempty(groupComparison.metricComparison)
    metricFile = fullfile(folder, "pairwise_metric_comparison.csv");
    writetable(groupComparison.metricComparison, metricFile);
    outputFiles.metricComparison = string(metricFile);
end

if isfield(groupComparison, "curveComparison") && ...
        ~isempty(fieldnames(groupComparison.curveComparison))
    curveTable = localCurveTable(groupComparison.curveComparison);
    curveFile = fullfile(folder, "pairwise_curve_comparison.csv");
    writetable(curveTable, curveFile);
    outputFiles.curveComparison = string(curveFile);

    figureHandle = mechanics.plotting.plotGroupComparison(groupComparison);
    figureCleanup = onCleanup(@() delete(figureHandle)); %#ok<NASGU>
    outputFiles.figure = mechanics.plotting.exportFigureFiles( ...
        figureHandle, folder, "tensile_study_comparison", "png", 200);
    outputFiles.figureFig = string( ...
        fullfile(folder, "tensile_study_comparison.fig"));
end

matFile = fullfile(folder, "tensile_study_comparison.mat");
save(matFile, "comparison");
outputFiles.comparison = string(matFile);

reportFile = fullfile(folder, "tensile_study_comparison.md");
localWriteReport(reportFile, comparison, compatibilityTable, outputFiles);
outputFiles.report = string(reportFile);
end

function output = localCompatibilityTable(comparison)
signatures = comparison.compatibility.studies(:);
count = numel(signatures);
group = comparison.groupLabels(:);
strainMeasure = strings(count,1);
stressMeasure = strings(count,1);
strainUnit = strings(count,1);
stressUnit = strings(count,1);
for index = 1:count
    strainMeasure(index) = string(signatures(index).strainMeasure);
    stressMeasure(index) = string(signatures(index).stressMeasure);
    strainUnit(index) = string(signatures(index).strainUnit);
    stressUnit(index) = string(signatures(index).stressUnit);
end
output = table(group, strainMeasure, stressMeasure, strainUnit, stressUnit, ...
    'VariableNames', {'Group','StrainMeasure','StressMeasure', ...
    'StrainUnit','StressUnit'});
end

function output = localCurveTable(comparison)
output = table(comparison.strain, comparison.meanStressA, ...
    comparison.meanStressB, comparison.meanDifference, ...
    comparison.confidenceLower, comparison.confidenceUpper, ...
    'VariableNames', {'Strain','MeanStressA','MeanStressB', ...
    'MeanDifference','ConfidenceLower','ConfidenceUpper'});
end

function localWriteReport(reportFile, comparison, compatibilityTable, outputFiles)
fileId = fopen(reportFile, "w");
if fileId < 0
    error("mechanics:io:ReportFileOpenFailed", ...
        "Could not open report file: %s", reportFile);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>

fprintf(fileId, "# Tensile study comparison\n\n");
fprintf(fileId, "Generated: %s\n\n", char(string(comparison.createdAt)));
fprintf(fileId, "Groups: %s\n\n", ...
    char(strjoin(comparison.groupLabels(:)', ", ")));

fprintf(fileId, "## Compatibility\n\n");
fprintf(fileId, "- Measures match: `%s`\n", ...
    char(string(comparison.compatibility.measuresMatch)));
fprintf(fileId, "- Units match: `%s`\n\n", ...
    char(string(comparison.compatibility.unitsMatch)));
mechanics.io.writeMarkdownTable(fileId, compatibilityTable);

fprintf(fileId, "## Study summary\n\n");
mechanics.io.writeMarkdownTable(fileId, comparison.studySummaries);

metricComparison = comparison.groupComparison.metricComparison;
if ~isempty(metricComparison)
    fprintf(fileId, "## Scalar metric comparison\n\n");
    mechanics.io.writeMarkdownTable(fileId, metricComparison);
end

if isfield(comparison.groupComparison, "curveComparison") && ...
        ~isempty(fieldnames(comparison.groupComparison.curveComparison))
    curve = comparison.groupComparison.curveComparison;
    fprintf(fileId, "## Curve comparison\n\n");
    fprintf(fileId, "- Group A: `%s` (n = %d)\n", ...
        char(string(curve.groupNameA)), curve.sampleCountA);
    fprintf(fileId, "- Group B: `%s` (n = %d)\n", ...
        char(string(curve.groupNameB)), curve.sampleCountB);
    fprintf(fileId, "- Common strain range: `[%g, %g] mm/mm`\n\n", ...
        curve.strain(1), curve.strain(end));
    if isfield(outputFiles, "figure")
        [~, name, extension] = fileparts(outputFiles.figure);
        fprintf(fileId, "![Tensile study comparison](%s%s)\n\n", ...
            char(string(name)), char(string(extension)));
    end
end

fprintf(fileId, "## Output files\n\n");
fields = fieldnames(outputFiles);
for index = 1:numel(fields)
    [~, name, extension] = fileparts(outputFiles.(fields{index}));
    fprintf(fileId, "- `%s%s`\n", char(string(name)), char(string(extension)));
end
end
