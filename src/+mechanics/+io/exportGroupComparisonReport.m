function reportFile = exportGroupComparisonReport(result, outputFiles, outputFolder)
%EXPORTGROUPCOMPARISONREPORT Export maintained group-comparison Markdown report.
arguments
    result (1,1) struct
    outputFiles (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

reportFile = fullfile(outputFolder, "group_comparison_report.md");
fileId = fopen(reportFile, "w");
if fileId < 0
    error("mechanics:io:GroupComparisonReportFileOpenFailed", ...
        "Could not open group comparison report: %s", reportFile);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>

fprintf(fileId, "# %s study comparison report\n\n", ...
    char(localTitleCase(localTestType(result))));
fprintf(fileId, "Generated: %s\n\n", char(string(result.createdAt)));

fprintf(fileId, "## Comparison summary\n\n");
group = string({result.groups.name})';
specimenCount = [result.groups.specimenCount]';
summaryTable = table(group, specimenCount, ...
    'VariableNames', {'Group','SpecimenCount'});
mechanics.io.writeMarkdownTable(fileId, summaryTable);

fprintf(fileId, "## Mechanical contract\n\n");
mechanicsMetadata = localMechanics(result);
contract = table( ...
    ["Test type";"Strain measure";"Stress measure";"Strain unit";"Stress unit"], ...
    [localTestType(result); mechanicsMetadata.strainMeasure; ...
     mechanicsMetadata.stressMeasure; localDisplayStrainUnit(mechanicsMetadata.strainUnit); ...
     mechanicsMetadata.stressUnit], ...
    'VariableNames', {'Field','Value'});
mechanics.io.writeMarkdownTable(fileId, contract);

if isfield(result, "metricComparison") && ~isempty(result.metricComparison)
    fprintf(fileId, "## Scalar metric comparison\n\n");
    metricTable = localMetricTable(result.metricComparison, mechanicsMetadata);
    mechanics.io.writeMarkdownTable(fileId, metricTable);
end

if isfield(result, "modelInitialShearSummary") && ...
        ~isempty(result.modelInitialShearSummary)
    fprintf(fileId, "## Model-derived initial shear modulus\n\n");
    shearTable = result.modelInitialShearSummary;
    shearTable.Models = localDisplayModelLists(shearTable.Models);
    mechanics.io.writeMarkdownTable(fileId, shearTable);
    fprintf(fileId, ...
        "The model-derived initial shear modulus $\\mu_0$ is a global small-strain constitutive reference. " + ...
        "It is shown with the tangent-modulus populations for context, but it is not the same quantity as the local tangent modulus.\n\n");
end

if isfield(result, "curveComparison") && ...
        ~isempty(fieldnames(result.curveComparison))
    fprintf(fileId, "## Curve comparison\n\n");
    fprintf(fileId, ...
        "The upper stress-strain panel shows the mean curve for each group with pointwise 95%% bootstrap confidence bands over the common strain range.\n\n");
    if localTestType(result) == "compression"
        groupA = string(result.curveComparison.groupNameA);
        groupB = string(result.curveComparison.groupNameB);
        fprintf(fileId, ...
            "The lower panel uses the compression presentation convention `|%s| - |%s|`. " + ...
            "Positive values therefore indicate larger compressive-stress magnitude for %s. " + ...
            "Stored processed stresses retain their physical negative signs.\n\n", ...
            char(groupB), char(groupA), char(groupB));
    else
        fprintf(fileId, ...
            "The lower panel shows the signed mean difference `group A - group B` with its pointwise 95%% bootstrap confidence interval.\n\n");
    end
end

localWriteInterpretationBoundaries(fileId, result);
localWriteFigures(fileId, outputFiles);

fprintf(fileId, "## Reproducibility\n\n");
fprintf(fileId, "- Comparison configuration is stored in `result.config`.\n");
fprintf(fileId, "- Complete grouped populations and pairwise results are stored in `group_comparison.mat`.\n");
fprintf(fileId, "- Group curve and metric tables are exported as CSV files.\n");
fprintf(fileId, "- Bootstrap settings are recorded in the stored configuration.\n");
end

function localWriteInterpretationBoundaries(fileId, result)
fprintf(fileId, "## Interpretation boundaries\n\n");
fprintf(fileId, ...
    "- Pairwise bootstrap intervals are descriptive uncertainty summaries for the configured specimen groups; this report does not convert interval exclusion of zero into a formal hypothesis-test claim.\n");

if isfield(result, "metricComparison") && ~isempty(result.metricComparison)
    comparison = result.metricComparison;
    for rowIndex = 1:height(comparison)
        metric = localMetricDisplayName(string(comparison.Metric(rowIndex)));
        difference = comparison.MeanDifference(rowIndex);
        lower = comparison.ConfidenceLower(rowIndex);
        upper = comparison.ConfidenceUpper(rowIndex);
        if ~all(isfinite([difference, lower, upper]))
            continue;
        end

        groupA = string(comparison.GroupA(rowIndex));
        groupB = string(comparison.GroupB(rowIndex));
        if lower <= 0 && upper >= 0
            fprintf(fileId, ...
                "- %s: the 95%% bootstrap interval for the mean difference includes zero, so the current comparison does not show a clear directional separation between `%s` and `%s` for this metric.\n", ...
                char(metric), char(groupA), char(groupB));
        elseif difference > 0
            fprintf(fileId, ...
                "- %s: the observed mean is higher for `%s` than for `%s`, and the 95%% bootstrap interval for A-minus-B remains above zero.\n", ...
                char(metric), char(groupA), char(groupB));
        else
            fprintf(fileId, ...
                "- %s: the observed mean is higher for `%s` than for `%s`, and the 95%% bootstrap interval for A-minus-B remains below zero.\n", ...
                char(metric), char(groupB), char(groupA));
        end
    end
end

if isfield(result, "modelInitialShearSummary") && ...
        height(result.modelInitialShearSummary) == 2
    shear = result.modelInitialShearSummary;
    values = shear.InitialShearModulus;
    if all(isfinite(values)) && all(values > 0)
        if values(1) ~= values(2)
            [largerValue, largerIndex] = max(values);
            smallerIndex = 3 - largerIndex;
            ratio = largerValue / values(smallerIndex);
            fprintf(fileId, ...
                "- Model-derived $\\mu_0$: `%s` is %.3g times the corresponding reference for `%s`. This ratio is a constitutive stiffness reference and must not be interpreted as a pointwise tangent-modulus ratio.\n", ...
                char(shear.Group(largerIndex)), ratio, char(shear.Group(smallerIndex)));
        end
    end
end

if localTestType(result) == "compression"
    fprintf(fileId, ...
        "- Compression curves retain negative stored stress. Magnitude-based presentation in the pairwise figure changes only interpretation of the plotted difference, not the stored numerical state.\n");
end
fprintf(fileId, "\n");
end

function tableOut = localMetricTable(tableIn, mechanicsMetadata)
tableOut = tableIn;
unit = strings(height(tableOut), 1);
for index = 1:height(tableOut)
    switch string(tableOut.Metric(index))
        case "MaximumStrain"
            unit(index) = localDisplayStrainUnit(mechanicsMetadata.strainUnit);
        case {"MaximumStress","MedianTangentModulus"}
            unit(index) = string(mechanicsMetadata.stressUnit);
        otherwise
            unit(index) = "";
    end
end
tableOut.Unit = unit;
end

function mechanicsMetadata = localMechanics(result)
mechanicsMetadata.strainMeasure = "";
mechanicsMetadata.stressMeasure = "";
mechanicsMetadata.strainUnit = "";
mechanicsMetadata.stressUnit = "";
if isfield(result, "mechanics")
    fields = fieldnames(mechanicsMetadata);
    for index = 1:numel(fields)
        field = fields{index};
        if isfield(result.mechanics, field)
            mechanicsMetadata.(field) = string(result.mechanics.(field));
        end
    end
end
end

function testType = localTestType(result)
testType = "uniaxial";
if isfield(result, "testType") && strlength(string(result.testType)) > 0
    testType = lower(string(result.testType));
end
end

function output = localDisplayStrainUnit(unit)
output = string(unit);
if output == "-" || output == "1" || strlength(output) == 0
    output = "mm/mm";
end
end

function output = localDisplayModelLists(modelLists)
modelLists = string(modelLists(:));
output = strings(size(modelLists));
for row = 1:numel(modelLists)
    names = strtrim(split(modelLists(row), ","));
    displayNames = strings(size(names));
    for index = 1:numel(names)
        if strlength(names(index)) == 0
            continue;
        end
        displayNames(index) = mechanics.models.modelRegistry(names(index)).displayName;
    end
    displayNames = displayNames(strlength(displayNames) > 0);
    output(row) = strjoin(displayNames, ", ");
end
end

function name = localMetricDisplayName(metric)
switch metric
    case "MaximumStrain"
        name = "Maximum strain";
    case "MaximumStress"
        name = "Maximum stress";
    case "MedianTangentModulus"
        name = "Median tangent modulus";
    otherwise
        name = metric;
end
end

function localWriteFigures(fileId, outputFiles)
figureFields = ["figure","metricFigure","tangentModulusFigure"];
labels = [ ...
    "Stress-strain population comparison"; ...
    "Scalar metric comparison"; ...
    "Tangent-modulus and model-derived initial shear comparison"];

available = false(size(figureFields));
for index = 1:numel(figureFields)
    available(index) = isfield(outputFiles, figureFields(index));
end
if ~any(available)
    return;
end

fprintf(fileId, "## Figures\n\n");
for index = 1:numel(figureFields)
    if ~available(index)
        continue;
    end
    path = string(outputFiles.(figureFields(index)));
    [~, name, extension] = fileparts(path);
    fprintf(fileId, "### %s\n\n![%s](%s%s)\n\n", ...
        char(labels(index)), char(labels(index)), char(name), char(extension));
end
end

function output = localTitleCase(value)
value = string(value);
if strlength(value) == 0
    output = "Uniaxial";
else
    output = upper(extractBefore(value, 2)) + extractAfter(value, 1);
end
end
