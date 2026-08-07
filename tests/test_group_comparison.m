function tests = test_group_comparison
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testGroupAssignment(testCase)
analysis = localAnalysis();
assignments = table( ...
    ["a1";"a2";"b1";"b2"], ...
    ["control";"control";"treated";"treated"], ...
    'VariableNames', {'SpecimenId','Group'});
analysis = mechanics.workflow.assignSpecimenGroups(analysis, assignments);
verifyEqual(testCase, analysis.summary.Group, ...
    ["control";"control";"treated";"treated"]);
end

function testBootstrapDifference(testCase)
config.enabled = true;
config.iterations = 300;
config.confidenceLevel = .95;
config.randomSeed = 4;
result = mechanics.statistics.bootstrapDifferenceOfMeans( ...
    [3 4 5], [1 2 3], config);
verifyEqual(testCase, result.meanDifference, 2, "AbsTol", 1e-12);
verifyLessThanOrEqual(testCase, result.lower, 2);
verifyGreaterThanOrEqual(testCase, result.upper, 2);
end

function testTwoGroupComparison(testCase)
result = localComparison();
verifyEqual(testCase, numel(result.groups), 2);
verifyEqual(testCase, result.groups(1).specimenCount, 2);
verifyEqual(testCase, result.curveComparison.meanDifference(end), ...
    -2, "AbsTol", 1e-12);
verifyEqual(testCase, height(result.metricComparison), 3);
verifyEqual(testCase, result.mechanics.strainMeasure, "engineering");
verifyEqual(testCase, result.mechanics.stressMeasure, "engineering");
verifyEqual(testCase, result.mechanics.strainUnit, "-");
verifyEqual(testCase, result.mechanics.stressUnit, "MPa");
verifyEqual(testCase, result.testType, "tension");
verifyEqual(testCase, result.modelInitialShearSummary.Group, ...
    ["control";"treated"]);
verifyEqual(testCase, ...
    result.modelInitialShearSummary.InitialShearModulus, ...
    [2;4], "AbsTol", 1e-12);
verifyEqual(testCase, result.modelInitialShearSummary.Models, ...
    ["neo-hookean";"neo-hookean"]);
end

function testCurveComparisonBootstrapIncludesGroupIntervals(testCase)
analysis = localAnalysis();
assignments = table( ...
    ["a1";"a2";"b1";"b2"], ...
    ["control";"control";"treated";"treated"], ...
    'VariableNames', {'SpecimenId','Group'});
analysis = mechanics.workflow.assignSpecimenGroups(analysis, assignments);
config = mechanics.config.groupComparisonConfig();
config.populationConfig.bootstrap.enabled = false;
config.populationConfig.strainGridPointCount = 21;
config.bootstrap.enabled = true;
config.bootstrap.iterations = 50;
result = mechanics.workflow.analyzeGroupComparison( ...
    analysis, ["control","treated"], config);
comparison = result.curveComparison;
verifyTrue(testCase, all(isfinite(comparison.confidenceLowerA)));
verifyTrue(testCase, all(isfinite(comparison.confidenceUpperA)));
verifyTrue(testCase, all(isfinite(comparison.confidenceLowerB)));
verifyTrue(testCase, all(isfinite(comparison.confidenceUpperB)));
verifyTrue(testCase, all(isfinite(comparison.confidenceLower)));
verifyTrue(testCase, all(isfinite(comparison.confidenceUpper)));
end

function testTangentModulusComparisonIncludesModelReference(testCase)
result = localComparison();
figureHandle = mechanics.plotting.plotGroupTangentModulusComparison(result);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
verifyTrue(testCase, isgraphics(figureHandle));
verifyEqual(testCase, ...
    figureHandle.UserData.initialShearSummary.InitialShearModulus, ...
    [2;4], "AbsTol", 1e-12);
verifyEqual(testCase, figureHandle.UserData.initialShearAnnotationCount, 2);
textHandles = findall(figureHandle, "Type", "text");
latexStrings = strings(0,1);
for index = 1:numel(textHandles)
    if string(textHandles(index).Interpreter) == "latex"
        latexStrings(end+1,1) = string(textHandles(index).String); %#ok<AGROW>
    end
end
verifyEqual(testCase, nnz(contains(latexStrings, "\mu_0")), 2);
end

function testMetricComparisonPlotUsesCompactTitlesAndAnnotations(testCase)
result = localComparison();
figureHandle = mechanics.plotting.plotGroupMetricComparison(result);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
verifyTrue(testCase, isgraphics(figureHandle));
axesHandles = findall(figureHandle, 'Type', 'axes', '-not', 'Tag', 'legend');
verifyEqual(testCase, numel(axesHandles), 3);
titles = strings(numel(axesHandles), 1);
annotationCount = 0;
for index = 1:numel(axesHandles)
    titles(index) = string(axesHandles(index).Title.String);
    textHandles = findall(axesHandles(index), "Type", "text");
    for textIndex = 1:numel(textHandles)
        annotationCount = annotationCount + ...
            contains(string(textHandles(textIndex).String), "Delta mean (A - B)");
    end
end
verifyTrue(testCase, all(ismember( ...
    ["Maximum strain";"Maximum stress";"Median tangent modulus"], titles)));
verifyEqual(testCase, annotationCount, 3);
end

function testCompressionPlotUsesMagnitudeDifferenceConvention(testCase)
result = localComparison();
result.testType = "compression";
comparison = result.curveComparison;
comparison.meanStressA = -abs(comparison.meanStressA);
comparison.meanStressB = -abs(comparison.meanStressB);
comparison.meanDifference = comparison.meanStressA - comparison.meanStressB;
result.curveComparison = comparison;
figureHandle = mechanics.plotting.plotGroupComparison(result);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
verifyEqual(testCase, figureHandle.UserData.differenceConvention, ...
    "compression-magnitude-B-minus-A");
end

function testExportCreatesFilesAndReport(testCase)
result = localComparison();
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportGroupComparison(result, folder);
verifyTrue(testCase, isfile(files.groupSummary));
verifyTrue(testCase, isfile(files.curveComparison));
verifyTrue(testCase, isfile(files.metricComparison));
verifyTrue(testCase, isfile(files.modelInitialShearSummary));
verifyTrue(testCase, isfile(files.comparison));
verifyTrue(testCase, isfile(files.figure));
verifyTrue(testCase, isfile(files.figureFig));
verifyTrue(testCase, isfile(files.metricFigure));
verifyTrue(testCase, isfile(files.metricFigureFig));
verifyTrue(testCase, isfile(files.tangentModulusFigure));
verifyTrue(testCase, isfile(files.tangentModulusFigureFig));
verifyTrue(testCase, isfile(files.report));
verifyEqual(testCase, string(files.figure), ...
    string(fullfile(folder, "group_comparison.png")));
verifyEqual(testCase, string(files.figureFig), ...
    string(fullfile(folder, "group_comparison.fig")));
verifyEqual(testCase, string(files.metricFigure), ...
    string(fullfile(folder, "group_metric_comparison.png")));
verifyEqual(testCase, string(files.tangentModulusFigure), ...
    string(fullfile(folder, "group_tangent_modulus_comparison.png")));
verifyEqual(testCase, string(files.report), ...
    string(fullfile(folder, "group_comparison_report.md")));

report = string(fileread(files.report));
verifyTrue(testCase, contains(report, "# Tension study comparison report"));
verifyTrue(testCase, contains(report, "## Scalar metric comparison"));
verifyTrue(testCase, contains(report, "## Model-derived initial shear modulus"));
verifyTrue(testCase, contains(report, "## Interpretation boundaries"));
verifyTrue(testCase, contains(report, "descriptive uncertainty summaries"));
verifyTrue(testCase, contains(report, "$\mu_0$"));
verifyTrue(testCase, contains(report, "group_comparison.png"));
verifyTrue(testCase, contains(report, "group_tangent_modulus_comparison.png"));
end

function testInsufficientGroupRejected(testCase)
analysis = localAnalysis();
assignments = table( ...
    ["a1";"a2";"b1";"b2"], ...
    ["control";"control";"treated";"other"], ...
    'VariableNames', {'SpecimenId','Group'});
analysis = mechanics.workflow.assignSpecimenGroups(analysis, assignments);
verifyError(testCase, @() mechanics.workflow.analyzeGroupComparison( ...
    analysis, ["control","treated"], ...
    mechanics.config.groupComparisonConfig()), ...
    "mechanics:workflow:InsufficientGroupSpecimens");
end

function result = localComparison()
analysis = localAnalysis();
assignments = table( ...
    ["a1";"a2";"b1";"b2"], ...
    ["control";"control";"treated";"treated"], ...
    'VariableNames', {'SpecimenId','Group'});
analysis = mechanics.workflow.assignSpecimenGroups(analysis, assignments);
config = mechanics.config.groupComparisonConfig();
config.populationConfig.bootstrap.enabled = false;
config.bootstrap.enabled = false;
config.populationConfig.strainGridPointCount = 21;
result = mechanics.workflow.analyzeGroupComparison( ...
    analysis, ["control","treated"], config);
end

function analysis = localAnalysis()
ids = ["a1";"a2";"b1";"b2"];
slopes = [2;2;4;4];
records = repmat(localRecord("", 1), 4, 1);
for index = 1:4
    records(index) = localRecord(ids(index), slopes(index));
end
analysis.records = records;
analysis.summary = table( ...
    ids, repmat("processed",4,1), ones(4,1), slopes, slopes, ...
    'VariableNames', {'SpecimenId','Status','MaximumStrain', ...
    'MaximumStress','MedianTangentModulus'});
end

function record = localRecord(id, slope)
strain = linspace(0,1,21)';
specimen.id = string(id);
specimen.testType = "tension";
specimen.processed.strain = strain;
specimen.processed.stress = slope .* strain;
specimen.processed.mechanicsConfig.strainMeasure = "engineering";
specimen.processed.mechanicsConfig.stressMeasure = "engineering";
specimen.processed.units.strain = "-";
specimen.processed.units.stress = "MPa";
specimen.analysis.tangentModulus.strain = strain;
specimen.analysis.tangentModulus.tangentModulusForPlot = ...
    repmat(slope, size(strain));

fitResult.parameterNames = "mu";
fitResult.parameters = slope;
modelRecord.modelName = "neo-hookean";
modelRecord.succeeded = true;
modelRecord.windowFraction = 1;
modelRecord.fitResult = fitResult;
specimen.modelSelection.selection.hasEligibleModel = true;
specimen.modelSelection.selection.bestModel = "neo-hookean";
specimen.modelSelection.records = modelRecord;

record.index = 1;
record.specimenId = string(id);
record.sheetName = string(id);
record.status = "processed";
record.quality = struct();
record.specimen = specimen;
record.errorIdentifier = "";
record.errorMessage = "";
record.group = "";
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
