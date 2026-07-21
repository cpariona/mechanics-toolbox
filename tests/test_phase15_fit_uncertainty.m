function tests = test_phase15_fit_uncertainty
tests = functiontests(localfunctions);
end

function setupOnce(~)
testFile = mfilename("fullpath");
repositoryRoot = fileparts(fileparts(testFile));
addpath(repositoryRoot);
run(fullfile(repositoryRoot, "startup.m"));
end

function testBootstrapParameterInterval(testCase)
fitResult = localFitResult();
config = localConfig();

uncertainty = mechanics.fitting.bootstrapFitUncertainty( ...
    fitResult, config);

verifyEqual(testCase, uncertainty.successfulCount, config.sampleCount);
verifySize(testCase, uncertainty.parameterSamples, ...
    [config.sampleCount, 1]);
verifyLessThan(testCase, uncertainty.parameterLower, ...
    uncertainty.parameterUpper);
verifyGreaterThan(testCase, fitResult.parameters, ...
    uncertainty.parameterLower);
verifyLessThan(testCase, fitResult.parameters, ...
    uncertainty.parameterUpper);
end

function testPredictionIntervalShape(testCase)
fitResult = localFitResult();
config = localConfig();
config.predictionDeformation = linspace(0, 0.5, 21)';

uncertainty = mechanics.fitting.bootstrapFitUncertainty( ...
    fitResult, config);

verifySize(testCase, uncertainty.predictionLower, [21, 1]);
verifySize(testCase, uncertainty.predictionUpper, [21, 1]);
verifyTrue(testCase, all(uncertainty.predictionUpper >= ...
    uncertainty.predictionLower));
end

function testUnknownMethodRejected(testCase)
fitResult = localFitResult();
config = localConfig();
config.method = "unknown";

verifyError(testCase, ...
    @() mechanics.fitting.bootstrapFitUncertainty( ...
        fitResult, config), ...
    "mechanics:fitting:UnknownBootstrapMethod");
end

function testUncertaintyExport(testCase)
fitResult = localFitResult();
uncertainty = mechanics.fitting.bootstrapFitUncertainty( ...
    fitResult, localConfig());

folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder));

files = mechanics.io.exportFitUncertainty( ...
    fitResult, uncertainty, folder);

verifyTrue(testCase, isfile(files.parameters));
verifyTrue(testCase, isfile(files.predictions));
verifyTrue(testCase, isfile(files.data));
end

function fitResult = localFitResult()
strain = linspace(0, 0.5, 41)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

trueStress = mechanics.models.evaluateModel( ...
    "neo-hookean", strain, 12, context);
noise = 0.12 .* sin((1:numel(strain))');
measuredStress = trueStress + noise;

fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 2;
fitConfig.randomSeed = 4;

fitResult = mechanics.fitting.fitModel( ...
    "neo-hookean", strain, measuredStress, context, fitConfig);
end

function config = localConfig()
config = mechanics.config.fitUncertaintyConfig();
config.sampleCount = 30;
config.randomSeed = 7;
config.minimumSuccessfulFraction = 1;
config.refitNumberOfStarts = 1;
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
