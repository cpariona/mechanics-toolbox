function tests = test_constitutive_models
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testRegisteredModels(testCase)
verifyEqual(testCase, mechanics.models.listModels(), ...
    ["neo-hookean", "mooney-rivlin", "yeoh-second-order", "yeoh"]);
end

function testRegisteredModelDisplayNames(testCase)
verifyEqual(testCase, mechanics.models.modelRegistry("neo-hookean").displayName, ...
    "Neo-Hookean");
verifyEqual(testCase, mechanics.models.modelRegistry("mooney-rivlin").displayName, ...
    "Mooney-Rivlin");
verifyEqual(testCase, mechanics.models.modelRegistry("yeoh-second-order").displayName, ...
    "Yeoh second order");
verifyEqual(testCase, mechanics.models.modelRegistry("yeoh").displayName, ...
    "Yeoh third order");
end

function testSecondOrderYeohRegistryMetadata(testCase)
model = mechanics.models.modelRegistry("yeoh-second-order");
verifyEqual(testCase, model.name, "yeoh-second-order");
verifyEqual(testCase, model.displayName, "Yeoh second order");
verifyEqual(testCase, model.functionHandle, @mechanics.models.yeoh);
verifyEqual(testCase, model.parameterNames, ["C10", "C20"]);
verifyEqual(testCase, model.defaultInitialGuess, [1, 0]);
verifyEqual(testCase, model.lowerBounds, [0, -Inf]);
verifyEqual(testCase, model.upperBounds, [Inf, Inf]);
verifyEqual(testCase, model.derivedQuantityNames, "mu0");
verifyEqual(testCase, model.evaluateDerivedQuantities([2, 0.1]), 4, ...
    "AbsTol", 1e-12);
end

function testExistingYeohRegistryRemainsThirdOrder(testCase)
model = mechanics.models.modelRegistry("yeoh");
verifyEqual(testCase, model.name, "yeoh");
verifyEqual(testCase, model.displayName, "Yeoh third order");
verifyEqual(testCase, model.parameterNames, ["C10", "C20", "C30"]);
verifyEqual(testCase, model.defaultInitialGuess, [1, 0, 0]);
verifyEqual(testCase, model.lowerBounds, [0, -Inf, -Inf]);
verifyEqual(testCase, model.upperBounds, [Inf, Inf, Inf]);
end

function testZeroStressAtReferenceConfiguration(testCase)
context.deformationMeasure = "stretch";
context.stressMeasure = "nominal";
verifyEqual(testCase, mechanics.models.evaluateModel("neo-hookean", 1, 2, context), 0, "AbsTol", 1e-12);
verifyEqual(testCase, mechanics.models.evaluateModel("mooney-rivlin", 1, [2, 1], context), 0, "AbsTol", 1e-12);
verifyEqual(testCase, mechanics.models.evaluateModel("yeoh-second-order", 1, [2, 1], context), 0, "AbsTol", 1e-12);
verifyEqual(testCase, mechanics.models.evaluateModel("yeoh", 1, [2, 1, 0.5], context), 0, "AbsTol", 1e-12);
end

function testSecondOrderYeohReducesToNeoHookeanWhenC20IsZero(testCase)
context.deformationMeasure = "stretch";
context.stressMeasure = "nominal";
lambda = linspace(1, 2, 21)';
C10 = 1.5;
secondOrderStress = mechanics.models.evaluateModel( ...
    "yeoh-second-order", lambda, [C10, 0], context);
neoHookeanStress = mechanics.models.evaluateModel( ...
    "neo-hookean", lambda, 2 * C10, context);
verifyEqual(testCase, secondOrderStress, neoHookeanStress, "AbsTol", 1e-12);
end

function testThirdOrderYeohContractIsPreserved(testCase)
context.deformationMeasure = "stretch";
context.stressMeasure = "nominal";
lambda = [1; 1.2; 1.5; 2.0];
parameters = [0.7, 0.08, 0.01];
I1minus3 = lambda.^2 + 2 .* lambda.^(-1) - 3;
dWdI1 = parameters(1) + ...
    2 .* parameters(2) .* I1minus3 + ...
    3 .* parameters(3) .* I1minus3.^2;
expected = 2 .* dWdI1 .* (lambda - lambda.^(-2));
actual = mechanics.models.evaluateModel("yeoh", lambda, parameters, context);
verifyEqual(testCase, actual, expected, "AbsTol", 1e-12);
end

function testRegisteredYeohOrdersEnforceParameterCount(testCase)
verifyError(testCase, ...
    @() mechanics.models.evaluateModel("yeoh-second-order", 0.1, 1), ...
    "mechanics:models:InvalidParameterCount");
verifyError(testCase, ...
    @() mechanics.models.evaluateModel("yeoh-second-order", 0.1, [1, 0.1, 0.01]), ...
    "mechanics:models:InvalidParameterCount");
verifyError(testCase, ...
    @() mechanics.models.evaluateModel("yeoh", 0.1, [1, 0.1]), ...
    "mechanics:models:InvalidParameterCount");
end

function testYeohRejectsUnsupportedParameterCount(testCase)
verifyError(testCase, ...
    @() mechanics.models.yeoh(0.1, 1), ...
    "mechanics:models:InvalidParameterCount");
verifyError(testCase, ...
    @() mechanics.models.yeoh(0.1, [1, 0.1, 0.01, 0.001]), ...
    "mechanics:models:InvalidParameterCount");
end

function testNeoHookeanKnownNominalStress(testCase)
context.deformationMeasure = "stretch";
context.stressMeasure = "nominal";
lambda = 2;
mu = 3;
expected = mu * (lambda - lambda^(-2));
actual = mechanics.models.evaluateModel("neo-hookean", lambda, mu, context);
verifyEqual(testCase, actual, expected, "AbsTol", 1e-12);
end

function testCauchyNominalConversion(testCase)
context.deformationMeasure = "stretch";
context.stressMeasure = "nominal";
lambda = [1; 1.2; 1.5];
nominal = mechanics.models.evaluateModel("neo-hookean", lambda, 2, context);
context.stressMeasure = "cauchy";
cauchy = mechanics.models.evaluateModel("neo-hookean", lambda, 2, context);
verifyEqual(testCase, cauchy, lambda .* nominal, "AbsTol", 1e-12);
end

function testEquivalentInputMeasures(testCase)
lambda = linspace(1, 2, 21)';
engineeringStrain = lambda - 1;
trueStrain = log(lambda);
parameters = [0.5, 0.2];
context.stressMeasure = "nominal";
context.deformationMeasure = "stretch";
fromStretch = mechanics.models.evaluateModel("mooney-rivlin", lambda, parameters, context);
context.deformationMeasure = "engineering-strain";
fromEngineering = mechanics.models.evaluateModel("mooney-rivlin", engineeringStrain, parameters, context);
context.deformationMeasure = "true-strain";
fromTrue = mechanics.models.evaluateModel("mooney-rivlin", trueStrain, parameters, context);
verifyEqual(testCase, fromEngineering, fromStretch, "AbsTol", 1e-12);
verifyEqual(testCase, fromTrue, fromStretch, "AbsTol", 1e-12);
end

function testOutputShapeIsPreserved(testCase)
strain = linspace(0, 0.5, 15);
stress = mechanics.models.evaluateModel("yeoh", strain, [1, 0.1, 0.01]);
verifySize(testCase, stress, size(strain));
secondOrderStress = mechanics.models.evaluateModel( ...
    "yeoh-second-order", strain, [1, 0.1]);
verifySize(testCase, secondOrderStress, size(strain));
end

function testUnknownModelIsRejected(testCase)
verifyError(testCase, ...
    @() mechanics.models.modelRegistry("unknown"), ...
    "mechanics:models:UnknownModel");
end

function testInvalidStretchIsRejected(testCase)
context.deformationMeasure = "stretch";
verifyError(testCase, ...
    @() mechanics.models.evaluateModel("neo-hookean", 0, 1, context), ...
    "mechanics:models:InvalidStretch");
end

function testInvalidParameterCountIsRejected(testCase)
verifyError(testCase, ...
    @() mechanics.models.evaluateModel("mooney-rivlin", 0.1, 1), ...
    "mechanics:models:InvalidParameterCount");
end
