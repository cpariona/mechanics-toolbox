function tests = test_phase20_fit_diagnostics_workflow
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testCompleteWorkflow(testCase)
[strain, stress, context] = localData();
config = mechanics.config.fitDiagnosticsWorkflowConfig();
config.bootstrapConfig.sampleCount = 25;
config.bootstrapConfig.randomSeed = 17;
config.identifiabilityConfig.minimumSuccessfulSamples = 10;

analysis = mechanics.workflow.runFitDiagnostics( ...
    "neo-hookean", strain, stress, context, struct(), config);

verifyTrue(testCase, isfield(analysis.fitResult, "parameters"));
verifyTrue(testCase, isfield(analysis.uncertainty, "successfulFraction"));
verifyTrue(testCase, isfield(analysis.identifiability, "weaklyIdentified"));
verifyTrue(testCase, isfield(analysis.windowStability, "stable"));
verifyTrue(testCase, isfield(analysis.residualDiagnostics, ...
    "hasSystematicStructure"));
verifyEqual(testCase, height(analysis.reliability.componentSummary), 6);
verifyEqual(testCase, height(analysis.diagnosticErrors), 0);
end

function testDisabledDiagnosticsProduceIncompleteAssessment(testCase)
[strain, stress, context] = localData();
config = mechanics.config.fitDiagnosticsWorkflowConfig();
config.runBootstrap = false;
config.runIdentifiability = false;
config.runWindowStability = false;
config.runResidualDiagnostics = false;
config.reliabilityConfig.requireAllDiagnostics = true;

analysis = mechanics.workflow.runFitDiagnostics( ...
    "neo-hookean", strain, stress, context, struct(), config);

verifyEqual(testCase, analysis.reliability.status, "incomplete");
verifyEqual(testCase, analysis.reliability.missingComponentCount, 4);
end

function testExportCreatesFiles(testCase)
[strain, stress, context] = localData();
config = mechanics.config.fitDiagnosticsWorkflowConfig();
config.runBootstrap = false;
config.runIdentifiability = false;
config.runWindowStability = false;
analysis = mechanics.workflow.runFitDiagnostics( ...
    "neo-hookean", strain, stress, context, struct(), config);

folder = string(tempname);
cleanup = onCleanup(@() localRemove(folder)); %#ok<NASGU>
files = mechanics.io.exportFitDiagnostics(analysis, folder);

verifyTrue(testCase, isfile(files.reliability));
verifyTrue(testCase, isfile(files.errors));
verifyTrue(testCase, isfile(files.summary));
verifyTrue(testCase, isfile(files.data));
end

function [strain, measuredStress, context] = localData()
strain = linspace(0, 0.6, 61)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
stress = mechanics.models.evaluateModel( ...
    "neo-hookean", strain, 15, context);
measuredStress = stress + 0.01 .* sin((1:numel(strain))');
end

function localRemove(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end