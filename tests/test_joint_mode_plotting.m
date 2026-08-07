function tests = test_joint_mode_plotting
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
set(groot, "defaultFigureVisible", "off");
end

function teardownOnce(~)
set(groot, "defaultFigureVisible", "on");
close all force
end

function testMeasuredCurvesPopulationMedianAndJointFitAreDistinct(testCase)
result = localResult("neo-hookean", "mu", 0.18, 1200);
figureHandle = mechanics.plotting.plotJointModeFit(result, "tension");
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>

lineObjects = findobj(figureHandle, "Type", "line");
displayNames = string(get(lineObjects, "DisplayName"));
fitMask = startsWith(displayNames, "Joint selected fit");
populationMask = displayNames == "Population median";
measuredMask = endsWith(displayNames, " measured");

verifyEqual(testCase, nnz(fitMask), 1);
verifyEqual(testCase, nnz(populationMask), 1);
verifyEqual(testCase, nnz(measuredMask), 2);
verifyEqual(testCase, string(lineObjects(fitMask).LineStyle), "--");
verifyEqual(testCase, lineObjects(fitMask).LineWidth, 1.8, "AbsTol", 1e-12);
verifyEqual(testCase, numel(lineObjects(fitMask).XData), 600);
verifyEqual(testCase, string(lineObjects(populationMask).LineStyle), "-");
verifyEqual(testCase, lineObjects(populationMask).LineWidth, 2.2, "AbsTol", 1e-12);
verifyEqual(testCase, numel(lineObjects(populationMask).XData), 400);
for object = reshape(lineObjects(measuredMask), 1, [])
    verifyEqual(testCase, string(object.LineStyle), "-");
    verifyEqual(testCase, string(object.Marker), "none");
    verifyEqual(testCase, object.LineWidth, 0.8, "AbsTol", 1e-12);
end

[textContent, textInterpreters] = localTextContent(figureHandle);
verifyTrue(testCase, any(contains(textContent, "\mu = 0.18 MPa")));
verifyTrue(testCase, any(textInterpreters == "tex" & ...
    contains(textContent, "\mu = 0.18 MPa")));
verifyFalse(testCase, any(contains(textContent, "mu0")));
verifyFalse(testCase, any(contains(textContent, "C10")));
end

function testPopulationMedianUsesOnlyCommonDomain(testCase)
result = localResult("neo-hookean", "mu", 0.2, 40);
result.selectedFit.specimens(1).Deformation = linspace(0, 1.0, 40)';
result.selectedFit.specimens(1).MeasuredStress = ...
    result.selectedFit.specimens(1).Deformation;
result.selectedFit.specimens(1).ObservationCount = 40;
result.selectedFit.specimens(2).Deformation = linspace(0.2, 0.8, 35)';
result.selectedFit.specimens(2).MeasuredStress = ...
    result.selectedFit.specimens(2).Deformation + 0.2;
result.selectedFit.specimens(2).ObservationCount = 35;

figureHandle = mechanics.plotting.plotJointModeFit(result, "tension");
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>
lineObjects = findobj(figureHandle, "Type", "line");
displayNames = string(get(lineObjects, "DisplayName"));
population = lineObjects(displayNames == "Population median");
verifyEqual(testCase, min(population.XData), 0.2, "AbsTol", 1e-12);
verifyEqual(testCase, max(population.XData), 0.8, "AbsTol", 1e-12);
verifyEqual(testCase, population.YData(:), population.XData(:) + 0.1, ...
    "AbsTol", 1e-10);
end

function testYeohAnnotationUsesRegistryDerivedQuantity(testCase)
parameterNames = ["C10", "C20", "C30"];
parameters = [0.052, 2e-4, 4e-6];
result = localResult("yeoh-third-order", parameterNames, parameters, 40);
figureHandle = mechanics.plotting.plotJointModeFit(result, "compression");
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>

lineObjects = findobj(figureHandle, "Type", "line");
displayNames = string(get(lineObjects, "DisplayName"));
verifyTrue(testCase, any(contains(displayNames, "Yeoh third order")));

[textContent, textInterpreters] = localTextContent(figureHandle);
verifyTrue(testCase, any(contains(textContent, "Yeoh third order")));
for index = 1:numel(parameterNames)
    verifyTrue(testCase, any(contains(textContent, parameterNames(index) + " =")));
end
verifyTrue(testCase, any(contains(textContent, "Derived quantities:")));
verifyTrue(testCase, any(contains(textContent, "\mu_0 = 0.104 MPa")));
verifyTrue(testCase, any(textInterpreters == "tex" & ...
    contains(textContent, "\mu_0 = 0.104 MPa")));
verifyFalse(testCase, any(contains(textContent, "mu0 =")));
verifyFalse(testCase, any(contains(textContent, "C01")));
end

function testMooneyRivlinDerivedQuantityComesFromRegistry(testCase)
model = mechanics.models.modelRegistry("mooney-rivlin");
verifyEqual(testCase, model.derivedQuantityNames, "mu0");
verifyEqual(testCase, model.evaluateDerivedQuantities([0.03, 0.02]), ...
    0.1, "AbsTol", 1e-12);
end

function testMismatchedParameterSummaryIsRejected(testCase)
result = localResult("neo-hookean", "mu", 0.2, 20);
result.selectedFit.parameterNames = ["mu", "extra"];
verifyError(testCase, @() mechanics.plotting.plotJointModeFit( ...
    result, "tension"), "mechanics:plotting:InvalidJointParameterSummary");
end

function result = localResult(modelName, parameterNames, parameters, pointCount)
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
modeName = "tension";
if modelName == "yeoh-third-order"
    modeName = "compression";
end
specimens = repmat(localSpecimen(modeName, "s1", modelName, ...
    parameters, context, pointCount, 0), 2, 1);
specimens(2) = localSpecimen(modeName, "s2", modelName, ...
    parameters, context, pointCount + 17, 0.01);
result.selectedModelName = string(modelName);
result.selectedFit.parameterNames = string(parameterNames);
result.selectedFit.parameters = parameters;
result.selectedFit.specimens = specimens;
end

function specimen = localSpecimen(modeName, specimenId, modelName, ...
        parameters, context, pointCount, stressOffset)
if modeName == "compression"
    deformation = linspace(-0.35, 0, pointCount)';
else
    deformation = linspace(0, 1.2, pointCount)';
end
stress = mechanics.models.evaluateModel( ...
    modelName, deformation, parameters, context) + stressOffset;
specimen.Mode = string(modeName);
specimen.OriginalSpecimenId = string(specimenId);
specimen.SpecimenId = modeName + "::" + specimenId;
specimen.Deformation = deformation;
specimen.MeasuredStress = stress;
specimen.PredictedStress = stress - stressOffset;
specimen.Context = context;
specimen.StrainUnit = "1";
specimen.StressUnit = "MPa";
specimen.ObservationCount = pointCount;
end

function [output, interpreters] = localTextContent(figureHandle)
objects = findall(figureHandle, "Type", "text");
output = strings(0, 1);
interpreters = strings(0, 1);
for index = 1:numel(objects)
    value = objects(index).String;
    if iscell(value)
        value = join(string(value), newline);
    end
    output(end+1, 1) = string(value); %#ok<AGROW>
    interpreters(end+1, 1) = string(objects(index).Interpreter); %#ok<AGROW>
end
end
