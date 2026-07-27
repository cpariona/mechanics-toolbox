function tests = test_study_consensus_model
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testLowestMedianBICIsSelected(testCase)
batch = localBatch([100 90 80; 102 92 82; 98 88 78], true(3,3));
config = mechanics.config.studyConsensusModelConfig();
config.bootstrap.iterations = 50;
result = mechanics.workflow.selectStudyConsensusModel(batch, config);
verifyTrue(testCase, result.hasConsensusModel);
verifyEqual(testCase, result.modelName, "yeoh");
verifyEqual(testCase, result.metricSummary.MedianBIC, [100;90;80]);
verifyEqual(testCase, result.metricSummary.DeltaBIC, [20;10;0]);
verifyEqual(testCase, result.reason, "Selected by lowest median BIC.");
verifyEqual(testCase, height(result.parameterSummary), 3);
end

function testBicTiePrefersFewerParameters(testCase)
batch = localBatch([80 79 78.5; 80 79 78.5; 80 79 78.5], true(3,3));
config = mechanics.config.studyConsensusModelConfig();
config.bicTieTolerance = 2;
config.bootstrap.enabled = false;
result = mechanics.workflow.selectStudyConsensusModel(batch, config);
verifyEqual(testCase, result.modelName, "neo-hookean");
verifyEqual(testCase, result.metricSummary.ParameterCount, [1;2;3]);
verifyEqual(testCase, result.reason, ...
    "Selected by parsimony among models within the median-BIC tie tolerance.");
end

function testInsufficientEligibilityReturnsNoConsensus(testCase)
eligible = [true false false; true false false; false false false];
batch = localBatch([80 70 60; 81 71 61; 82 72 62], eligible);
config = mechanics.config.studyConsensusModelConfig();
config.minimumEligibleFraction = 0.75;
result = mechanics.workflow.selectStudyConsensusModel(batch, config);
verifyFalse(testCase, result.hasConsensusModel);
verifyEqual(testCase, result.modelName, "");
verifyEqual(testCase, height(result.parameterTable), 0);
verifyTrue(testCase, all(isnan(result.metricSummary.DeltaBIC)));
end

function testConsensusPlotIsCreated(testCase)
batch = localBatch([100 90 80; 102 92 82; 98 88 78], true(3,3));
config = mechanics.config.studyConsensusModelConfig();
config.bootstrap.enabled = false;
result = mechanics.workflow.selectStudyConsensusModel(batch, config);
figureHandle = mechanics.plotting.plotStudyConsensusModel(result);
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
verifyTrue(testCase, isgraphics(figureHandle));
end

function testConsensusExportCreatesFiles(testCase)
batch = localBatch([100 90 80; 102 92 82; 98 88 78], true(3,3));
config = mechanics.config.studyConsensusModelConfig();
config.bootstrap.enabled = false;
result = mechanics.workflow.selectStudyConsensusModel(batch, config);
folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportStudyConsensusModel(result, folder);
verifyTrue(testCase, isfile(files.metrics));
verifyTrue(testCase, isfile(files.parameters));
verifyTrue(testCase, isfile(files.parameterSummary));
verifyTrue(testCase, isfile(files.figure));
verifyTrue(testCase, isfile(files.figureFig));
verifyTrue(testCase, isfile(files.data));
end

function batch = localBatch(bicMatrix, eligibleMatrix)
models = ["neo-hookean";"mooney-rivlin";"yeoh"];
parameterCounts = [1;2;3];
specimenCount = size(bicMatrix,1);
batch.modelNames = models;
batch.specimenCount = specimenCount;
batch.specimenSummary = table("S" + (1:specimenCount)', ...
    repmat("all",specimenCount,1), true(specimenCount,1), ...
    true(specimenCount,1), repmat("yeoh",specimenCount,1), ...
    zeros(specimenCount,1), strings(specimenCount,1), strings(specimenCount,1), ...
    'VariableNames', {'SpecimenId','Group','Success','HasSelectedModel', ...
    'SelectedModelName','SelectedCriterionValue','ErrorIdentifier','ErrorMessage'});
batch.comparisons = cell(specimenCount,1);
for specimenIndex = 1:specimenCount
    success = true(3,1);
    eligible = eligibleMatrix(specimenIndex,:)';
    normalizedRMSE = [0.03;0.02;0.01] + specimenIndex .* 1e-4;
    summary = table(models, success, repmat("reliable",3,1), eligible, ...
        parameterCounts, normalizedRMSE, normalizedRMSE, 1-normalizedRMSE, ...
        bicMatrix(specimenIndex,:)' - 5, bicMatrix(specimenIndex,:)' - 2, ...
        bicMatrix(specimenIndex,:)', bicMatrix(specimenIndex,:)', (1:3)', ...
        strings(3,1), strings(3,1), ...
        'VariableNames', {'ModelName','Success','ReliabilityStatus','Eligible', ...
        'ParameterCount','RMSE','NormalizedRMSE','RSquared','AIC','AICc','BIC', ...
        'CriterionValue','Rank','ErrorIdentifier','ErrorMessage'});
    analyses = cell(3,1);
    analyses{1}.fitResult.modelName = "neo-hookean";
    analyses{1}.fitResult.parameters = 10 + specimenIndex;
    analyses{2}.fitResult.modelName = "mooney-rivlin";
    analyses{2}.fitResult.parameters = [3;2] + specimenIndex;
    analyses{3}.fitResult.modelName = "yeoh";
    analyses{3}.fitResult.parameters = [4;0.5;0.1] + specimenIndex;
    comparison.summary = summary;
    comparison.analyses = analyses;
    batch.comparisons{specimenIndex} = comparison;
end
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder,'s');
end
end