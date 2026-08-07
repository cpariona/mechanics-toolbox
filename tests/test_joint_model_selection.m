function tests = test_joint_model_selection
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testParsimonySelectsNeoHookeanForNeoHookeanData(testCase)
config = localConfig();
studies = {
    localStudy("tension", ["t1"; "t2"], "neo-hookean", 2.4), ...
    localStudy("compression", ["c1"; "c2"; "c3"], "neo-hookean", 2.4)};
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
result = mechanics.workflow.selectJointModel(normalized, config);

verifyEqual(testCase, result.selectedModelName, "neo-hookean");
verifyEqual(testCase, height(result.candidateSummary), 3);
verifyTrue(testCase, all(result.candidateSummary.Eligible));
verifyTrue(testCase, result.candidateSummary.PracticallyEquivalent(1));
verifyEqual(testCase, result.selectedFit.parameters, 2.4, "AbsTol", 1e-4);
end

function testYeohIsSelectedForNonlinearYeohData(testCase)
config = localConfig();
parameters = [0.7, 1.8, 0.9];
studies = {
    localStudy("tension", ["t1"; "t2"], "yeoh", parameters), ...
    localStudy("compression", ["c1"; "c2"], "yeoh", parameters)};
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
result = mechanics.workflow.selectJointModel(normalized, config);

verifyEqual(testCase, result.selectedModelName, "yeoh");
verifyEqual(testCase, result.selectedFit.parameters, parameters, "AbsTol", 2e-3);
verifyLessThan(testCase, result.selectedFit.objective, 1e-8);
verifyTrue(testCase, all(isfinite(result.candidateSummary.AIC)));
verifyTrue(testCase, all(isfinite(result.candidateSummary.BIC)));
end

function testSecondOrderYeohCanBeSelectedExplicitly(testCase)
config = localConfig();
config.candidateModelNames = ["yeoh-second-order"; "yeoh"];
config.selection.tieBreakOrder = config.candidateModelNames;
parameters = [0.7, 0.18];
studies = {
    localStudy("tension", ["t1"; "t2"], "yeoh-second-order", parameters), ...
    localStudy("compression", ["c1"; "c2"], "yeoh-second-order", parameters)};
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
result = mechanics.workflow.selectJointModel(normalized, config);

verifyEqual(testCase, result.candidateSummary.ParameterCount, [2; 3]);
verifyEqual(testCase, result.selectedModelName, "yeoh-second-order");
verifyEqual(testCase, result.selectedFit.parameters, parameters, ...
    "RelTol", 2e-2, "AbsTol", 2e-3);
verifyLessThan(testCase, result.selectedFit.objective, 1e-8);
end

function testFailedCandidateIsRetainedAndIgnored(testCase)
config = localConfig();
config.candidateModelNames = ["unknown-model"; "neo-hookean"];
config.selection.tieBreakOrder = config.candidateModelNames;
studies = {
    localStudy("tension", "t", "neo-hookean", 1.6), ...
    localStudy("compression", "c", "neo-hookean", 1.6)};
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
result = mechanics.workflow.selectJointModel(normalized, config);

verifyEqual(testCase, result.selectedModelName, "neo-hookean");
verifyEqual(testCase, result.candidateSummary.Status, ["failed"; "completed"]);
verifyFalse(testCase, result.candidateSummary.Eligible(1));
verifyNotEmpty(testCase, result.candidates(1).errorIdentifier);
end

function testTieBreakOrderIsDeterministicAfterComplexityAndObjective(testCase)
config = localConfig();
config.candidateModelNames = ["neo-hookean"; "neo-hookean"];
verifyError(testCase, @() mechanics.workflow.selectJointModel(struct(), config), ...
    "mechanics:workflow:InvalidJointCandidateModels");
end

function testInvalidSelectionToleranceIsRejected(testCase)
config = localConfig();
config.selection.practicalObjectiveTolerance = -1;
studies = {
    localStudy("tension", "t", "neo-hookean", 2), ...
    localStudy("compression", "c", "neo-hookean", 2)};
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
verifyError(testCase, @() mechanics.workflow.selectJointModel(normalized, config), ...
    "mechanics:workflow:InvalidJointObjectiveTolerance");
end

function config = localConfig()
config = mechanics.config.jointMaterialCharacterizationConfig();
config.fitting.numberOfStarts = 6;
config.fitting.randomSeed = 11;
config.fitting.maxIterations = 4000;
config.fitting.maxFunctionEvaluations = 15000;
config.selection.practicalObjectiveTolerance = 0.02;
end

function study = localStudy(mode, specimenIds, modelName, parameters)
specimenIds = string(specimenIds(:));
records = repmat(localRecord(mode, "", modelName, parameters, 41), ...
    numel(specimenIds), 1);
for index = 1:numel(specimenIds)
    records(index) = localRecord( ...
        mode, specimenIds(index), modelName, parameters, 31 + 6 * index);
end
study.analysis.records = records;
study.analysis.summary = table(specimenIds, repmat("processed", numel(specimenIds), 1), ...
    'VariableNames', {'SpecimenId','Status'});
study.populationStatus = "completed";
study.config = struct();
end

function record = localRecord(mode, specimenId, modelName, parameters, pointCount)
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
if mode == "tension"
    deformation = linspace(0, 1.0, pointCount)';
else
    deformation = linspace(0, -0.4, pointCount)';
end
stress = mechanics.models.evaluateModel(modelName, deformation, parameters, context);
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
