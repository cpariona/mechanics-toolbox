function tests = test_measurement_monte_carlo
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testAreaUnitsNormalizeToSquareMillimetres(testCase)
[area, unit, conversion] = mechanics.io.normalizeAreaUnits([1; 2], "cm^2");
verifyEqual(testCase, area, [100; 200], "AbsTol", 1e-12);
verifyEqual(testCase, unit, "mm2");
verifyEqual(testCase, conversion.factor, 100);
end

function testMeasurementMonteCarloRefitsParameters(testCase)
[specimen, fit] = localTensionFit();
config = mechanics.config.measurementMonteCarloFitConfig();
config.sampleCount = 20;
config.initialLengthStd = 0.1;
config.initialAreaStd = 0.1;
config.refitNumberOfStarts = 1;
result = mechanics.fitting.measurementMonteCarloFitUncertainty( ...
    specimen, fit, config);
verifyGreaterThanOrEqual(testCase, result.successfulFraction, 0.8);
verifySize(testCase, result.parameterSamples, [20, 1]);
verifyLessThan(testCase, result.parameterLower(1), result.parameterUpper(1));
end

function testForceAndDisplacementMonteCarlo(testCase)
[specimen, fit] = localTensionFit();
config = mechanics.config.measurementMonteCarloFitConfig();
config.sampleCount = 20;
config.forceStd = 0.01;
config.displacementStd = 0.005;
config.refitNumberOfStarts = 1;
result = mechanics.fitting.measurementMonteCarloFitUncertainty( ...
    specimen, fit, config);
verifyGreaterThanOrEqual(testCase, result.successfulFraction, 0.8);
verifyGreaterThan(testCase, ...
    std(result.parameterSamples(result.successMask, 1)), 0);
end

function [specimen, fit] = localTensionFit()
strain = linspace(0, 0.25, 41)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
stress = mechanics.models.evaluateModel("neo-hookean", strain, 3, context);
fit = mechanics.fitting.fitModel("neo-hookean", strain, stress, context, ...
    mechanics.config.fittingConfig());
specimen.geometry.initialLength = 25;
specimen.geometry.initialArea = 10;
specimen.processed.displacement = strain .* 25;
specimen.processed.force = stress .* 10;
specimen.processed.strain = strain;
specimen.processed.stress = stress;
specimen.processingConfig = mechanics.config.tensionConfig();
end
