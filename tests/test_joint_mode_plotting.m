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

function testDenseMeasurementsAreDecimatedAndJointFitIsProminent(testCase)
result = localResult("neo-hookean", "mu", 0.18, 1200);
figureHandle = mechanics.plotting.plotJointModeFit(result, "tension");
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>

lineObjects = findobj(figureHandle, "Type", "line");
displayNames = string(get(lineObjects, "DisplayName"));
fitMask = startsWith(displayNames, "Joint selected fit");
measuredMask = endsWith(displayNames, " measured");

verifyEqual(testCase, nnz(fitMask), 1);
verifyEqual(testCase, nnz(measuredMask), 2);
verifyGreaterThanOrEqual(testCase, lineObjects(fitMask).LineWidth, 2.5);
verifyEqual(testCase, numel(lineObjects(fitMask).XData), 600);
for object = reshape(lineObjects(measuredMask), 1, [])
    verifyLessThanOrEqual(testCase, numel(object.XData), 250);
    verifyEqual(testCase, string(object.LineStyle), "none");
    verifyLessThanOrEqual(testCase, object.MarkerSize, 3);
end

textContent = localTextContent(figureHandle);
verifyTrue(testCase, any(contains(textContent, "mu = 0.18 MPa")));
verifyFalse(testCase, any(contains(textContent, "C10")));
end

function testParameterAnnotationUsesSelectedModelContract(testCase)
parameterNames = ["C10", "C20", "C30"];
parameters = [0.052, 2e-4, 4e-6];
result = localResult("yeoh", parameterNames, parameters, 40);
figureHandle = mechanics.plotting.plotJointModeFit(result, "compression");
cleanup = onCleanup(@() close(figureHandle)); %#ok<NASGU>

textContent = localTextContent(figureHandle);
for index = 1:numel(parameterNames)
    verifyTrue(testCase, any(contains(textContent, parameterNames(index) + " =")));
end
verifyFalse(testCase, any(contains(textContent, "C01")));

lineObjects = findobj(figureHandle, "Type", "line");
displayNames = string(get(lineObjects, "DisplayName"));
verifyEqual(testCase, nnz(startsWith(displayNames, ...
    "Joint selected fit (yeoh)")), 1);
verifyFalse(testCase, any(contains(displayNames, "selected fit") & ...
    ~startsWith(displayNames, "Joint selected fit")));
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
if modelName == "yeoh"
    modeName = "compression";
end
specimens = repmat(localSpecimen(modeName, "s1", modelName, ...
    parameters, context, pointCount), 2, 1);
specimens(2) = localSpecimen(modeName, "s2", modelName, ...
    parameters, context, pointCount + 17);
result.selectedModelName = string(modelName);
result.selectedFit.parameterNames = string(parameterNames);
result.selectedFit.parameters = parameters;
result.selectedFit.specimens = specimens;
end

function specimen = localSpecimen(modeName, specimenId, modelName, ...
        parameters, context, pointCount)
if modeName == "compression"
    deformation = linspace(-0.35, 0, pointCount)';
else
    deformation = linspace(0, 1.2, pointCount)';
end
stress = mechanics.models.evaluateModel( ...
    modelName, deformation, parameters, context);
specimen.Mode = string(modeName);
specimen.OriginalSpecimenId = string(specimenId);
specimen.SpecimenId = modeName + "::" + specimenId;
specimen.Deformation = deformation;
specimen.MeasuredStress = stress;
specimen.PredictedStress = stress;
specimen.Context = context;
specimen.StrainUnit = "1";
specimen.StressUnit = "MPa";
specimen.ObservationCount = pointCount;
end

function output = localTextContent(figureHandle)
objects = findall(figureHandle, "Type", "text");
output = strings(0, 1);
for index = 1:numel(objects)
    value = objects(index).String;
    if iscell(value)
        value = join(string(value), newline);
    end
    output(end+1, 1) = string(value); %#ok<AGROW>
end
end
