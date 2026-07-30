function tests = test_joint_fixed_model_fitting
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testNeoHookeanParametersAreRecoveredAcrossUnpairedModes(testCase)
trueMu = 2.5;
studies = {
    localStudy("tension", ["shared"; "tension-only"], trueMu, [17; 31]), ...
    localStudy("compression", ["shared"; "compression-2"; "compression-3"], ...
        trueMu, [13; 23; 37])};
config = localConfig();
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
fit = mechanics.fitting.fitJointModel(normalized, "neo-hookean", config);

verifyEqual(testCase, fit.modelName, "neo-hookean");
verifyEqual(testCase, fit.parameters, trueMu, "AbsTol", 1e-5);
verifyLessThan(testCase, fit.objective, 1e-10);
verifyEqual(testCase, height(fit.specimenSummary), 5);
verifyEqual(testCase, fit.modeSummary.SpecimenCount, [2; 3]);
verifyEqual(testCase, fit.modeWeights, [0.5; 0.5], "AbsTol", 1e-12);
verifyTrue(testCase, all(fit.specimenSummary.NormalizedRMSE < 1e-5));
verifyTrue(testCase, all(arrayfun(@(x) ...
    isfield(x, "PredictedStress") && isfield(x, "Residuals"), fit.specimens)));
end

function testConfiguredModeWeightsAreNormalized(testCase)
trueMu = 1.8;
studies = {
    localStudy("tension", "a", trueMu, 21), ...
    localStudy("compression", "b", trueMu, 21)};
config = localConfig();
config.modeWeights = [3; 1];
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
fit = mechanics.fitting.fitJointModel(normalized, "neo-hookean", config);

verifyEqual(testCase, fit.modeWeights, [0.75; 0.25], "AbsTol", 1e-12);
verifyEqual(testCase, fit.modeSummary.Weight, [0.75; 0.25], "AbsTol", 1e-12);
verifyEqual(testCase, fit.parameters, trueMu, "AbsTol", 1e-5);
end

function testResponseRangeNormalizationIsIndependentOfSamplingDensity(testCase)
trueMu = 3.2;
coarseStudies = {
    localStudy("tension", "t", trueMu, 9), ...
    localStudy("compression", "c", trueMu, 11)};
denseStudies = {
    localStudy("tension", "t", trueMu, 101), ...
    localStudy("compression", "c", trueMu, 151)};
config = localConfig();
coarse = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    coarseStudies, ["tension"; "compression"], config);
dense = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    denseStudies, ["tension"; "compression"], config);
coarseFit = mechanics.fitting.fitJointModel(coarse, "neo-hookean", config);
denseFit = mechanics.fitting.fitJointModel(dense, "neo-hookean", config);

verifyEqual(testCase, coarseFit.parameters, trueMu, "AbsTol", 1e-5);
verifyEqual(testCase, denseFit.parameters, trueMu, "AbsTol", 1e-5);
verifyEqual(testCase, coarseFit.parameters, denseFit.parameters, "AbsTol", 1e-5);
end

function testUnknownNormalizationIsRejected(testCase)
config = localConfig();
studies = {
    localStudy("tension", "t", 2, 11), ...
    localStudy("compression", "c", 2, 11)};
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
config.normalization.method = "maximum-stress";
verifyError(testCase, @() mechanics.fitting.fitJointModel( ...
    normalized, "neo-hookean", config), ...
    "mechanics:fitting:UnknownJointNormalization");
end

function testInvalidModeWeightsAreRejected(testCase)
config = localConfig();
studies = {
    localStudy("tension", "t", 2, 11), ...
    localStudy("compression", "c", 2, 11)};
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
config.modeWeights = [1; 0];
verifyError(testCase, @() mechanics.fitting.fitJointModel( ...
    normalized, "neo-hookean", config), ...
    "mechanics:fitting:InvalidJointModeWeights");
end

function config = localConfig()
config = mechanics.config.jointMaterialCharacterizationConfig();
config.fitting.initialGuess = 1;
config.fitting.numberOfStarts = 4;
config.fitting.randomSeed = 7;
config.fitting.maxIterations = 2000;
config.fitting.maxFunctionEvaluations = 5000;
end

function study = localStudy(mode, specimenIds, mu, pointCounts)
specimenIds = string(specimenIds(:));
pointCounts = pointCounts(:);
if isscalar(pointCounts)
    pointCounts = repmat(pointCounts, numel(specimenIds), 1);
end
records = repmat(localRecord(mode, "", mu, pointCounts(1)), ...
    numel(specimenIds), 1);
for index = 1:numel(specimenIds)
    records(index) = localRecord(mode, specimenIds(index), mu, pointCounts(index));
end
study.analysis.records = records;
study.analysis.summary = table(specimenIds, repmat("processed", numel(specimenIds), 1), ...
    'VariableNames', {'SpecimenId','Status'});
study.populationStatus = "completed";
study.config = struct();
end

function record = localRecord(mode, specimenId, mu, pointCount)
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
if mode == "tension"
    deformation = linspace(0, 0.8, pointCount)';
else
    deformation = linspace(0, -0.35, pointCount)';
end
stress = mechanics.models.evaluateModel("neo-hookean", deformation, mu, context);
processed.strain = deformation;
processed.stress = stress;
processed.units.strain = "1";
processed.units.stress = "MPa";
processed.mechanicsConfig.strainMeasure = "engineering";
processed.mechanicsConfig.stressMeasure = "engineering";
specimen.id = string(specimenId);
specimen.testType = string(mode);
specimen.processed = processed;
record.index = 1;
record.specimenId = string(specimenId);
record.sheetName = string(specimenId);
record.status = "processed";
record.quality = struct();
record.specimen = specimen;
record.errorIdentifier = "";
record.errorMessage = "";
record.group = "";
end
