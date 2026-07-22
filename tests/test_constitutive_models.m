function tests = test_constitutive_models
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testRegisteredModels(testCase)
verifyEqual(testCase, mechanics.models.listModels(), ...
    ["neo-hookean", "mooney-rivlin", "yeoh"]);
end

function testZeroStressAtReferenceConfiguration(testCase)
context.inputMeasure = "stretch";
context.outputStressMeasure = "nominal";
verifyEqual(testCase, mechanics.models.evaluateModel("neo-hookean", 1, 2, context), 0, "AbsTol", 1e-12);
verifyEqual(testCase, mechanics.models.evaluateModel("mooney-rivlin", 1, [2, 1], context), 0, "AbsTol", 1e-12);
verifyEqual(testCase, mechanics.models.evaluateModel("yeoh", 1, [2, 1, 0.5], context), 0, "AbsTol", 1e-12);
end

function testNeoHookeanKnownNominalStress(testCase)
context.inputMeasure = "stretch";
context.outputStressMeasure = "nominal";
lambda = 2;
mu = 3;
expected = mu * (lambda - lambda^(-2));
actual = mechanics.models.evaluateModel("neo-hookean", lambda, mu, context);
verifyEqual(testCase, actual, expected, "AbsTol", 1e-12);
end

function testCauchyNominalConversion(testCase)
context.inputMeasure = "stretch";
context.outputStressMeasure = "nominal";
lambda = [1; 1.2; 1.5];
nominal = mechanics.models.evaluateModel("neo-hookean", lambda, 2, context);
context.outputStressMeasure = "cauchy";
cauchy = mechanics.models.evaluateModel("neo-hookean", lambda, 2, context);
verifyEqual(testCase, cauchy, lambda .* nominal, "AbsTol", 1e-12);
end

function testEquivalentInputMeasures(testCase)
lambda = linspace(1, 2, 21)';
engineeringStrain = lambda - 1;
trueStrain = log(lambda);
parameters = [0.5, 0.2];
context.outputStressMeasure = "nominal";
context.inputMeasure = "stretch";
fromStretch = mechanics.models.evaluateModel("mooney-rivlin", lambda, parameters, context);
context.inputMeasure = "engineering-strain";
fromEngineering = mechanics.models.evaluateModel("mooney-rivlin", engineeringStrain, parameters, context);
context.inputMeasure = "true-strain";
fromTrue = mechanics.models.evaluateModel("mooney-rivlin", trueStrain, parameters, context);
verifyEqual(testCase, fromEngineering, fromStretch, "AbsTol", 1e-12);
verifyEqual(testCase, fromTrue, fromStretch, "AbsTol", 1e-12);
end

function testOutputShapeIsPreserved(testCase)
strain = linspace(0, 0.5, 15);
stress = mechanics.models.evaluateModel("yeoh", strain, [1, 0.1, 0.01]);
verifySize(testCase, stress, size(strain));
end

function testUnknownModelIsRejected(testCase)
verifyError(testCase, ...
    @() mechanics.models.modelRegistry("unknown"), ...
    "mechanics:models:UnknownModel");
end

function testInvalidStretchIsRejected(testCase)
context.inputMeasure = "stretch";
verifyError(testCase, ...
    @() mechanics.models.evaluateModel("neo-hookean", 0, 1, context), ...
    "mechanics:models:InvalidStretch");
end

function testInvalidParameterCountIsRejected(testCase)
verifyError(testCase, ...
    @() mechanics.models.evaluateModel("mooney-rivlin", 0.1, 1), ...
    "mechanics:models:InvalidParameterCount");
end
