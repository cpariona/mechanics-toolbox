function tests = test_phase21_reliability_aware_model_comparison
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testNeoHookeanSelectedForNeoHookeanData(testCase)
[strain, stress, context] = localData();
fitConfig = mechanics.config.fittingConfig();
config = localFastConfig();

comparison = mechanics.workflow.compareModelsWithDiagnostics( ...
    ["neo-hookean", "mooney-rivlin"], strain, stress, context, ...
    fitConfig, config);

verifyTrue(testCase, comparison.hasSelectedModel);
verifyEqual(testCase, comparison.selectedModelName, "neo-hookean");
verifyEqual(testCase, height(comparison.summary), 2);
verifyTrue(testCase, all(comparison.summary.Success));
verifyTrue(testCase, all(comparison.summary.Eligible));
end

function testUnknownModelCanBeRecorded(testCase)
[strain, stress, context] = localData();
fitConfig = mechanics.config.fittingConfig();
config = localFastConfig();
config.requireEligibleModel = false;

comparison = mechanics.workflow.compareModelsWithDiagnostics( ...
    ["neo-hookean", "not-a-model"], strain, stress, context, ...
    fitConfig, config);

verifyTrue(testCase, comparison.summary.Success(1));
verifyFalse(testCase, comparison.summary.Success(2));
verifyNotEmpty(testCase, comparison.summary.ErrorIdentifier(2));
end

function testUnknownCriterionRejected(testCase)
[strain, stress, context] = localData();
fitConfig = mechanics.config.fittingConfig();
config = localFastConfig();
config.selectionCriterion = "unknown";

verifyError(testCase, @() mechanics.workflow.compareModelsWithDiagnostics( ...
    "neo-hookean", strain, stress, context, fitConfig, config), ...
    "mechanics:workflow:UnknownModelSelectionCriterion");
end

function testExportCreatesFiles(testCase)
[strain, stress, context] = localData();
fitConfig = mechanics.config.fittingConfig();
config = localFastConfig();
comparison = mechanics.workflow.compareModelsWithDiagnostics( ...
    ["neo-hookean", "mooney-rivlin"], strain, stress, context, ...
    fitConfig, config);

folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportModelComparison(comparison, folder);

verifyTrue(testCase, isfile(files.summary));
verifyTrue(testCase, isfile(files.selection));
verifyTrue(testCase, isfile(files.data));
end

function config = localFastConfig()
config = mechanics.config.modelComparisonWorkflowConfig();
config.fitDiagnosticsConfig.runBootstrap = false;
config.fitDiagnosticsConfig.runIdentifiability = false;
config.fitDiagnosticsConfig.runWindowStability = false;
config.fitDiagnosticsConfig.runResidualDiagnostics = false;
end

function [strain, measuredStress, context] = localData()
strain = linspace(0, 0.6, 61)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
measuredStress = mechanics.models.evaluateModel( ...
    "neo-hookean", strain, 15, context);
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
