function tests = test_tensile_application_range_fitting
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testNeoHookeanSharedParameterIsRecovered(testCase)
parameters = 0.18;
normalized = localNormalized("neo-hookean", parameters, [31; 47]);
config = localConfig("neo-hookean");
fit = mechanics.fitting.fitTensileApplicationRangeModel( ...
    normalized, "neo-hookean", config);

verifyEqual(testCase, fit.modelName, "neo-hookean");
verifyEqual(testCase, fit.parameterNames, "mu");
verifyEqual(testCase, fit.parameters, parameters, "RelTol", 2e-4);
verifyLessThan(testCase, fit.objective, 1e-10);
verifyEqual(testCase, numel(fit.specimens), 2);
verifyEqual(testCase, fit.specimenWeighting, "equal");
verifyTrue(testCase, all(isfinite(fit.specimenSummary.RMSE)));
verifyTrue(testCase, all(isfield(fit.specimens, ...
    ["PredictedStress","Residuals","NormalizationScale"])));
end

function testSecondOrderYeohSharedParametersAreRecovered(testCase)
parameters = [0.052, 0.08];
normalized = localNormalized("yeoh-second-order", parameters, [51; 67]);
config = localConfig("yeoh-second-order");
config.fitting.numberOfStarts = 12;
fit = mechanics.fitting.fitTensileApplicationRangeModel( ...
    normalized, "yeoh-second-order", config);

verifyEqual(testCase, fit.modelName, "yeoh-second-order");
verifyEqual(testCase, fit.parameterNames, ["C10", "C20"]);
verifyEqual(testCase, fit.parameters, parameters, "RelTol", 2e-2, ...
    "AbsTol", 2e-6);
verifyLessThan(testCase, fit.objective, 1e-8);
end

function testThirdOrderYeohSharedParametersAreRecovered(testCase)
parameters = [0.052, 2e-4, 4e-6];
normalized = localNormalized("yeoh-third-order", parameters, [51; 67]);
config = localConfig("yeoh-third-order");
config.fitting.numberOfStarts = 12;
fit = mechanics.fitting.fitTensileApplicationRangeModel( ...
    normalized, "yeoh-third-order", config);

verifyEqual(testCase, fit.modelName, "yeoh-third-order");
verifyEqual(testCase, fit.parameters, parameters, "RelTol", 2e-2, ...
    "AbsTol", 2e-6);
verifyLessThan(testCase, fit.objective, 1e-8);
end

function testDuplicatingSamplesDoesNotChangeEqualSpecimenFit(testCase)
normalized = localNormalized("neo-hookean", 0.2, [31; 41]);
config = localConfig("neo-hookean");
fitA = mechanics.fitting.fitTensileApplicationRangeModel( ...
    normalized, "neo-hookean", config);

expanded = normalized;
expanded.specimens(1).Deformation = repelem( ...
    normalized.specimens(1).Deformation, 5);
expanded.specimens(1).MeasuredStress = repelem( ...
    normalized.specimens(1).MeasuredStress, 5);
expanded.specimens(1).ObservationCount = ...
    numel(expanded.specimens(1).Deformation);
expanded.observationCount = sum([expanded.specimens.ObservationCount]);
fitB = mechanics.fitting.fitTensileApplicationRangeModel( ...
    expanded, "neo-hookean", config);

verifyEqual(testCase, fitB.parameters, fitA.parameters, "AbsTol", 1e-10);
verifyEqual(testCase, fitB.objective, fitA.objective, "AbsTol", 1e-12);
end

function testCandidateWorkflowRetainsOneResultPerModel(testCase)
normalized = localNormalized("neo-hookean", 0.16, [31; 43]);
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.candidateModelNames = [ ...
    "neo-hookean"; "mooney-rivlin"; ...
    "yeoh-second-order"; "yeoh-third-order"];
config.fitting.numberOfStarts = 4;
candidates = mechanics.workflow.fitTensileApplicationRangeModels( ...
    normalized, config);

verifyEqual(testCase, string({candidates.modelName})', ...
    config.candidateModelNames);
verifyEqual(testCase, string({candidates.status})', ...
    repmat("completed", 4, 1));
verifyTrue(testCase, all(isfinite([candidates.objective])));
verifyEqual(testCase, [candidates.parameterCount], [1, 2, 2, 3]);
end

function testUnsupportedSpecimenWeightingIsRejected(testCase)
normalized = localNormalized("neo-hookean", 0.2, [31; 41]);
config = localConfig("neo-hookean");
config.specimenWeighting = "pointwise";
verifyError(testCase, @() mechanics.fitting ...
    .fitTensileApplicationRangeModel(normalized, "neo-hookean", config), ...
    "mechanics:fitting:UnsupportedTensileApplicationRangeWeighting");
end

function testInvalidNormalizationIsRejected(testCase)
normalized = localNormalized("neo-hookean", 0.2, [31; 41]);
config = localConfig("neo-hookean");
config.normalization.method = "none";
verifyError(testCase, @() mechanics.fitting ...
    .fitTensileApplicationRangeModel(normalized, "neo-hookean", config), ...
    "mechanics:fitting:UnknownTensileApplicationRangeNormalization");
end

function config = localConfig(modelName)
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.candidateModelNames = string(modelName);
config.fitting.numberOfStarts = 8;
config.fitting.randomSeed = 3;
end

function normalized = localNormalized(modelName, parameters, pointCounts)
pointCounts = pointCounts(:);
specimens = repmat(localSpecimen("", modelName, parameters, 21), ...
    numel(pointCounts), 1);
for index = 1:numel(pointCounts)
    specimens(index) = localSpecimen( ...
        "s" + index, modelName, parameters, pointCounts(index));
    specimens(index).SourceRecordIndex = index;
end
normalized.specimens = specimens;
normalized.specimenCount = numel(specimens);
normalized.observationCount = sum([specimens.ObservationCount]);
normalized.requestedFitRange = [0, 0.30];
normalized.deformationMeasure = "engineering-strain";
end

function specimen = localSpecimen(specimenId, modelName, parameters, pointCount)
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
deformation = linspace(0, 0.30, pointCount)';
stress = mechanics.models.evaluateModel( ...
    modelName, deformation, parameters, context);
specimen.SourceRecordIndex = 1;
specimen.SourceSpecimenId = string(specimenId);
specimen.SourceSheetName = "";
specimen.FullDeformation = deformation;
specimen.FullMeasuredStress = stress;
specimen.IncludedIndices = (1:pointCount)';
specimen.ExcludedIndices = zeros(0, 1);
specimen.Deformation = deformation;
specimen.MeasuredStress = stress;
specimen.AvailableRange = [0, 0.30];
specimen.RequestedFitRange = [0, 0.30];
specimen.FittedRange = [0, 0.30];
specimen.Context = context;
specimen.StrainUnit = "1";
specimen.StressUnit = "MPa";
specimen.ObservationCount = pointCount;
specimen.ExcludedObservationCount = 0;
end
