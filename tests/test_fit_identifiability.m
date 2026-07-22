function tests = test_fit_identifiability
tests = functiontests(localfunctions);
end

function setupOnce(~)
testFile = mfilename("fullpath");
repositoryRoot = fileparts(fileparts(testFile));
addpath(repositoryRoot);
run(fullfile(repositoryRoot, "startup.m"));
end

function testStableSingleParameter(testCase)
[fitResult, uncertainty] = localSingleParameterInput();
config = localConfig();

diagnostics = mechanics.fitting.analyzeFitIdentifiability( ...
    fitResult, uncertainty, config);

verifyFalse(testCase, diagnostics.weaklyIdentified);
verifyEqual(testCase, size(diagnostics.correlationMatrix), [1, 1]);
verifyEqual(testCase, height(diagnostics.parameterSummary), 1);
verifyFalse(testCase, diagnostics.parameterSummary.WeaklyIdentified);
end

function testHighCorrelationIsDetected(testCase)
rng(2, "twister");
base = linspace(-1, 1, 100)';
samples = [10 + base, 5 - 0.5 .* base + 0.001 .* randn(100, 1)];

fitResult = localFitResult([10, 5], ["C10", "C01"], [0, 0], [100, 100]);
uncertainty = localUncertainty(samples, [9; 4.5], [11; 5.5]);
config = localConfig();
config.correlationThreshold = 0.90;

diagnostics = mechanics.fitting.analyzeFitIdentifiability( ...
    fitResult, uncertainty, config);

verifyTrue(testCase, diagnostics.hasHighCorrelation);
verifyTrue(testCase, diagnostics.weaklyIdentified);
verifyEqual(testCase, height(diagnostics.highCorrelationPairs), 1);
verifyGreaterThan(testCase, ...
    abs(diagnostics.correlationMatrix(1,2)), 0.99);
end

function testBoundaryHitsAreDetected(testCase)
samples = [zeros(25,1); linspace(1, 5, 75)'];
fitResult = localFitResult(2, "mu", 0, 10);
uncertainty = localUncertainty(samples, 0, 5);
config = localConfig();
config.boundaryHitFractionThreshold = 0.20;

diagnostics = mechanics.fitting.analyzeFitIdentifiability( ...
    fitResult, uncertainty, config);

verifyTrue(testCase, diagnostics.parameterSummary.WeakByBoundary);
verifyTrue(testCase, diagnostics.weaklyIdentified);
end

function testInsufficientSamplesRejected(testCase)
[fitResult, uncertainty] = localSingleParameterInput();
uncertainty.successMask(6:end) = false;
uncertainty.successfulCount = 5;
config = localConfig();

verifyError(testCase, ...
    @() mechanics.fitting.analyzeFitIdentifiability( ...
        fitResult, uncertainty, config), ...
    "mechanics:fitting:InsufficientIdentifiabilitySamples");
end

function testExportCreatesFiles(testCase)
[fitResult, uncertainty] = localSingleParameterInput();
diagnostics = mechanics.fitting.analyzeFitIdentifiability( ...
    fitResult, uncertainty, localConfig());
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder));

files = mechanics.io.exportFitIdentifiability(diagnostics, folder);

verifyTrue(testCase, isfile(files.parameters));
verifyTrue(testCase, isfile(files.correlation));
verifyTrue(testCase, isfile(files.highCorrelationPairs));
verifyTrue(testCase, isfile(files.data));
end

function [fitResult, uncertainty] = localSingleParameterInput()
rng(1, "twister");
samples = 10 + 0.1 .* randn(100, 1);
fitResult = localFitResult(10, "mu", 0, 100);
uncertainty = localUncertainty(samples, 9.8, 10.2);
end

function fitResult = localFitResult(parameters, names, lower, upper)
fitResult.modelName = "synthetic";
fitResult.parameters = parameters;
fitResult.parameterNames = names;
fitResult.config.lowerBounds = lower;
fitResult.config.upperBounds = upper;
end

function uncertainty = localUncertainty(samples, lower, upper)
uncertainty.parameterSamples = samples;
uncertainty.successMask = true(size(samples,1), 1);
uncertainty.parameterLower = lower;
uncertainty.parameterUpper = upper;
uncertainty.successfulCount = size(samples,1);
end

function config = localConfig()
config = mechanics.config.fitIdentifiabilityConfig();
config.minimumSuccessfulSamples = 10;
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
