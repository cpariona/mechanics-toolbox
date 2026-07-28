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
end

function testExportCreatesFiles(testCase)
result = localComparison();
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportGroupComparison(result, folder);
verifyTrue(testCase, isfile(files.groupSummary));
verifyTrue(testCase, isfile(files.curveComparison));
verifyTrue(testCase, isfile(files.metricComparison));
verifyTrue(testCase, isfile(files.comparison));
verifyTrue(testCase, isfile(files.figure));
verifyTrue(testCase, isfile(files.figureFig));
verifyEqual(testCase, string(files.figure), ...
    string(fullfile(folder, "group_comparison.png")));
verifyEqual(testCase, string(files.figureFig), ...
    string(fullfile(folder, "group_comparison.fig")));
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
specimen.processed.strain = strain;
specimen.processed.stress = slope .* strain;
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