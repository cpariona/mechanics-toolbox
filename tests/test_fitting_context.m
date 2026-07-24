function tests = test_fitting_context
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testTrueStrainAndCauchyStressContext(testCase)
trueStrain = log([1; 1.2; 1.5]);
context.deformationMeasure = "true-strain";
context.stressMeasure = "cauchy";
mu = 2;
lambda = exp(trueStrain);
expected = lambda .* mu .* (lambda - lambda .^ (-2));
actual = mechanics.models.evaluateModel( ...
    "neo-hookean", trueStrain, mu, context);
verifyEqual(testCase, actual, expected, "AbsTol", 1e-12);
end

function testRemovedDeformationMeasureFieldRejected(testCase)
context.inputMeasure = "engineering-strain";
verifyError(testCase, @() mechanics.models.evaluateModel( ...
    "neo-hookean", [0; 0.1], 1, context), ...
    "mechanics:models:RemovedDeformationMeasureField");
end

function testRemovedStressMeasureFieldRejected(testCase)
context.outputStressMeasure = "nominal";
verifyError(testCase, @() mechanics.models.evaluateModel( ...
    "neo-hookean", [0; 0.1], 1, context), ...
    "mechanics:models:RemovedStressMeasureField");
end
