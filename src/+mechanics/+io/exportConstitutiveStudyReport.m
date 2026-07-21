function files = exportConstitutiveStudyReport(batch, population, inference, config)
%EXPORTCONSTITUTIVESTUDYREPORT Export final figures and Markdown report.
arguments
    batch (1,1) struct
    population (1,1) struct
    inference (1,1) struct
    config (1,1) struct = mechanics.config.constitutiveStudyReportConfig()
end

folder = string(config.outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end
figureFiles = mechanics.plotting.exportConstitutiveStudyFigures( ...
    batch, population, inference, config);
reportFile = fullfile(folder, string(config.reportFilename));
fileId = fopen(reportFile, "w");
if fileId < 0
    error("mechanics:io:ConstitutiveReportFileOpenFailed", ...
        "Could not open report file: %s", reportFile);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>

fprintf(fileId, "# Constitutive study report\n\n");
fprintf(fileId, "Generated: %s\n\n", char(string(datetime("now"))));

fprintf(fileId, "## Model selection\n\n");
fprintf(fileId, "| Metric | Value |\n|---|---:|\n");
fprintf(fileId, "| Specimens | %d |\n", batch.specimenCount);
fprintf(fileId, "| Successful comparisons | %d |\n", ...
    batch.successfulSpecimenCount);
fprintf(fileId, "| Specimens with selected model | %d |\n\n", ...
    batch.selectedSpecimenCount);
localWriteTable(fileId, batch.modelSummary);

fprintf(fileId, "\n## Selected-model parameters\n\n");
fprintf(fileId, "Parameter observations: %d  \n", ...
    population.parameterObservationCount);
fprintf(fileId, "Specimens represented: %d\n\n", population.specimenCount);
localWriteTable(fileId, population.overallSummary);

fprintf(fileId, "\n## Group-level parameter summaries\n\n");
if isempty(population.groupSummary)
    fprintf(fileId, "No group-level parameter summary was available.\n\n");
else
    localWriteTable(fileId, population.groupSummary);
end

fprintf(fileId, "\n## Inferential group comparisons\n\n");
fprintf(fileId, "| Metric | Value |\n|---|---:|\n");
fprintf(fileId, "| Comparisons | %d |\n", inference.comparisonCount);
fprintf(fileId, "| Successful comparisons | %d |\n", ...
    inference.successfulComparisonCount);
fprintf(fileId, "| Significant comparisons | %d |\n\n", ...
    inference.significantComparisonCount);
localWriteInferenceTable(fileId, inference.comparisonTable, ...
    config.significanceAlpha);

fields = fieldnames(figureFiles);
if ~isempty(fields)
    fprintf(fileId, "\n## Figures\n\n");
    for index = 1:numel(fields)
        path = string(figureFiles.(fields{index}));
        [~, name, extension] = fileparts(path);
        label = regexprep(fields{index}, "([a-z])([A-Z])", "$1 $2");
        fprintf(fileId, "### %s\n\n", label);
        fprintf(fileId, "![%s](%s%s)\n\n", ...
            label, name, extension);
    end
end

fprintf(fileId, "## Interpretation limits\n\n");
fprintf(fileId, "%s", [ ...
    '- Model selection is conditional on the candidate models, ' ...
    'fit configuration, and reliability filters.' newline]);
fprintf(fileId, "%s", [ ...
    '- Parameters are summarized only within the same model ' ...
    'family and parameter identity.' newline]);
fprintf(fileId, "%s", [ ...
    '- Adjusted p-values and effect sizes should be interpreted ' ...
    'with specimen counts and diagnostic quality.' newline]);

files = figureFiles;
files.report = string(reportFile);
end

function localWriteTable(fileId, input)
if isempty(input)
    fprintf(fileId, "No data available.\n");
    return;
end
names = string(input.Properties.VariableNames);
fprintf(fileId, "| %s |\n", strjoin(names, " | "));
fprintf(fileId, "|%s|\n", strjoin(repmat("---", size(names)), "|"));
for row = 1:height(input)
    values = strings(1, width(input));
    for column = 1:width(input)
        values(column) = localFormat(input{row,column});
    end
    fprintf(fileId, "| %s |\n", strjoin(values, " | "));
end
end

function localWriteInferenceTable(fileId, input, alpha)
if isempty(input)
    fprintf(fileId, "No inferential comparisons were available.\n");
    return;
end
selected = input(:, {'ModelName','Parameter','Group1','Group2', ...
    'MeanDifference','ConfidenceIntervalLower','ConfidenceIntervalUpper', ...
    'HedgesG','CliffsDelta','AdjustedPValue','Significant'});
localWriteTable(fileId, selected);
fprintf(fileId, "\nSignificance threshold: adjusted p < %.4g.\n", alpha);
end

function output = localFormat(value)
if iscell(value)
    value = value{1};
end
if isstring(value) || ischar(value) || iscategorical(value)
    output = string(value);
elseif islogical(value)
    output = string(value);
elseif isnumeric(value)
    if isempty(value)
        output = "";
    elseif isscalar(value)
        output = string(sprintf("%.6g", value));
    else
        output = string(mat2str(value));
    end
elseif isdatetime(value)
    output = string(value);
else
    output = string(value);
end
output = replace(output, "|", "\\|");
end
