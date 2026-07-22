function tests = test_fit_reliability
tests = functiontests(localfunctions);
end

function setupOnce(~)
testFile = mfilename("fullpath");
repositoryRoot = fileparts(fileparts(testFile));
addpath(repositoryRoot);
run(fullfile(repositoryRoot, "startup.m"));
end

function testReliableAssessment(testCase)
fitResult = localFitResult(true, 0.03, 0.99);
uncertainty.successfulFraction = 0.95;
identifiability.weaklyIdentified = false;
windowStability.stable = true;
residualDiagnostics.hasSystematicStructure = false;

assessment = mechanics.fitting.assessFitReliability( ...
    fitResult, uncertainty, identifiability, ...
    windowStability, residualDiagnostics);

verifyEqual(testCase, assessment.status, "reliable");
verifyEqual(testCase, assessment.flagCount, 0);
verifyEqual(testCase, assessment.missingComponentCount, 0);
end

function testCautionAssessment(testCase)
fitResult = localFitResult(true, 0.03, 0.99);
identifiability.weaklyIdentified = true;
windowStability.stable = false;

assessment = mechanics.fitting.assessFitReliability( ...
    fitResult, struct(), identifiability, windowStability, struct());

verifyEqual(testCase, assessment.status, "caution");
verifyEqual(testCase, assessment.flagCount, 2);
verifyEqual(testCase, assessment.missingComponentCount, 2);
end

function testUnreliableAssessment(testCase)
fitResult = localFitResult(false, 0.20, 0.80);
uncertainty.successfulFraction = 0.40;
identifiability.weaklyIdentified = true;
windowStability.stable = false;
residualDiagnostics.hasSystematicStructure = true;

assessment = mechanics.fitting.assessFitReliability( ...
    fitResult, uncertainty, identifiability, ...
    windowStability, residualDiagnostics);

verifyEqual(testCase, assessment.status, "unreliable");
verifyGreaterThan(testCase, assessment.flagCount, 2);
end

function testRequireAllDiagnostics(testCase)
fitResult = localFitResult(true, 0.03, 0.99);
config = mechanics.config.fitReliabilityConfig();
config.requireAllDiagnostics = true;

assessment = mechanics.fitting.assessFitReliability( ...
    fitResult, struct(), struct(), struct(), struct(), config);

verifyEqual(testCase, assessment.status, "incomplete");
end

function testExportCreatesFiles(testCase)
fitResult = localFitResult(true, 0.03, 0.99);
assessment = mechanics.fitting.assessFitReliability(fitResult);
folder = string(tempname);
cleanup = onCleanup(@() localCleanup(folder)); %#ok<NASGU>

files = mechanics.io.exportFitReliability(assessment, folder);
verifyTrue(testCase, isfile(files.components));
verifyTrue(testCase, isfile(files.summary));
verifyTrue(testCase, isfile(files.data));
end

function fitResult = localFitResult(converged, normalizedRmse, rSquared)
fitResult.modelName = "neo-hookean";
fitResult.converged = converged;
fitResult.metrics.normalizedRmse = normalizedRmse;
fitResult.metrics.rSquared = rSquared;
end

function localCleanup(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
