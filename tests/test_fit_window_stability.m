function tests = test_fit_window_stability
tests = functiontests(localfunctions);
end

function setupOnce(~)
testFile = mfilename("fullpath");
repositoryRoot = fileparts(fileparts(testFile));
addpath(repositoryRoot);
run(fullfile(repositoryRoot, "startup.m"));
end

function testStableNeoHookeanAcrossWindows(testCase)
[x, y, context] = localNeoHookeanData();
config = localConfig();
fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 2;

stability = mechanics.fitting.analyzeFitWindowStability( ...
    "neo-hookean", x, y, context, fitConfig, config);

verifyEqual(testCase, stability.successfulWindowCount, ...
    numel(config.windowFractions));
verifySize(testCase, stability.parameterMatrix, ...
    [numel(config.windowFractions), 1]);
verifyTrue(testCase, stability.stable);
verifyLessThan(testCase, ...
    stability.parameterSummary.RelativeRange, 0.05);
end

function testWindowSummaryIsCreated(testCase)
[x, y, context] = localNeoHookeanData();
stability = mechanics.fitting.analyzeFitWindowStability( ...
    "neo-hookean", x, y, context, ...
    mechanics.config.fittingConfig(), localConfig());

verifyEqual(testCase, height(stability.windowSummary), 4);
verifyEqual(testCase, stability.windowSummary.WindowFraction, ...
    localConfig().windowFractions(:));
verifyTrue(testCase, all(stability.windowSummary.Success));
end

function testInvalidFractionsRejected(testCase)
[x, y, context] = localNeoHookeanData();
config = localConfig();
config.windowFractions = [0.5, 1.2];

verifyError(testCase, ...
    @() mechanics.fitting.analyzeFitWindowStability( ...
        "neo-hookean", x, y, context, ...
        mechanics.config.fittingConfig(), config), ...
    "mechanics:fitting:InvalidWindowFractions");
end

function testExportCreatesFiles(testCase)
[x, y, context] = localNeoHookeanData();
stability = mechanics.fitting.analyzeFitWindowStability( ...
    "neo-hookean", x, y, context, ...
    mechanics.config.fittingConfig(), localConfig());

folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder));
files = mechanics.io.exportFitWindowStability(stability, folder);

verifyTrue(testCase, isfile(files.windows));
verifyTrue(testCase, isfile(files.parameters));
verifyTrue(testCase, isfile(files.data));
end

function config = localConfig()
config = mechanics.config.fitWindowStabilityConfig();
config.windowFractions = [0.4, 0.6, 0.8, 1.0];
config.minimumObservations = 8;
config.minimumSuccessfulWindows = 3;
config.relativeParameterRangeThreshold = 0.10;
end

function [x, y, context] = localNeoHookeanData()
x = linspace(0, 0.8, 81)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
y = mechanics.models.evaluateModel( ...
    "neo-hookean", x, 12, context);
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
