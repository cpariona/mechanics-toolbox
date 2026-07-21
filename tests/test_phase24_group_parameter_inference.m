function tests = test_phase24_group_parameter_inference
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testDetectsClearGroupDifference(testCase)
population = localPopulation([10 11 9 10.5], [20 21 19 20.5]);
config = localConfig();
inference = mechanics.workflow.compareSelectedParametersBetweenGroups( ...
    population, config);
verifyEqual(testCase, inference.comparisonCount, 1);
verifyLessThan(testCase, inference.comparisonTable.AdjustedPValue, 0.05);
verifyTrue(testCase, inference.comparisonTable.Significant);
verifyLessThan(testCase, inference.comparisonTable.MeanDifference, 0);
end

function testInsufficientGroupSizeIsRecorded(testCase)
population = localPopulation([10 11], [20 21]);
config = localConfig();
config.minimumSpecimensPerGroup = 3;
inference = mechanics.workflow.compareSelectedParametersBetweenGroups( ...
    population, config);
verifyEqual(testCase, inference.successfulComparisonCount, 0);
verifyNotEmpty(testCase, inference.comparisonTable.ErrorIdentifier(1));
end

function testMultipleParametersAreKeptSeparate(testCase)
population = localPopulation([10 11 9 10.5], [20 21 19 20.5]);
extra = population.parameterTable;
extra.Parameter(:) = "beta";
extra.Value = extra.Value .* 2;
population.parameterTable = [population.parameterTable; extra];
config = localConfig();
inference = mechanics.workflow.compareSelectedParametersBetweenGroups( ...
    population, config);
verifyEqual(testCase, inference.comparisonCount, 2);
verifyEqual(testCase, numel(unique(inference.comparisonTable.Parameter)), 2);
end

function testExportCreatesFiles(testCase)
population = localPopulation([10 11 9 10.5], [20 21 19 20.5]);
inference = mechanics.workflow.compareSelectedParametersBetweenGroups( ...
    population, localConfig());
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportGroupParameterInference(inference, folder);
verifyTrue(testCase, isfile(files.comparisons));
verifyTrue(testCase, isfile(files.summary));
verifyTrue(testCase, isfile(files.data));
end

function config = localConfig()
config = mechanics.config.groupParameterInferenceConfig();
config.permutationCount = 199;
config.bootstrapCount = 200;
config.randomSeed = 7;
end

function population = localPopulation(groupA, groupB)
value = [groupA(:); groupB(:)];
group = [repmat("A",numel(groupA),1); repmat("B",numel(groupB),1)];
count = numel(value);
population.parameterTable = table( ...
    "S" + (1:count)', group, repmat("neo-hookean",count,1), ...
    repmat("mu",count,1), value, nan(count,1), nan(count,1), nan(count,1), ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter', ...
    'Value','BootstrapLower','BootstrapMedian','BootstrapUpper'});
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder,'s');
end
end
