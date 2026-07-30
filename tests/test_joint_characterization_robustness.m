function tests = test_joint_characterization_robustness
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testKnownModelIsStableAcrossOneFactorScenarios(testCase)
trueMu = 2.4;
studies = {
    localStudy("tension", ["t1"; "t2"; "t3"], trueMu, [41; 61; 81]), ...
    localStudy("compression", ["c1"; "c2"], trueMu, [51; 71])};
config = localConfig();
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
auditConfig = mechanics.config.jointCharacterizationAuditConfig();
audit = mechanics.workflow.auditJointMaterialCharacterization( ...
    normalized, config, auditConfig);

verifyEqual(testCase, height(audit.scenarioSummary), 6);
verifyTrue(testCase, all(audit.scenarioSummary.SelectedModel == "neo-hookean"));
verifyTrue(testCase, all(audit.scenarioSummary.SameModelAsBaseline));
verifyLessThan(testCase, max(audit.scenarioSummary.ParameterRelativeChange), 1e-4);
verifyEqual(testCase, audit.baseline.selectedFit.parameters, trueMu, "AbsTol", 1e-5);
verifyEqual(testCase, audit.scenarioSummary.Perturbation(1), "none");
verifyTrue(testCase, any(audit.scenarioSummary.Perturbation == "mode weights"));
verifyTrue(testCase, any(audit.scenarioSummary.Perturbation == "sampling density"));
verifyTrue(testCase, any(audit.scenarioSummary.Perturbation == "deformation range"));
verifyTrue(testCase, any(audit.scenarioSummary.Perturbation == "specimen count"));
end

function testAuditDoesNotMutateNormalizedInput(testCase)
studies = {
    localStudy("tension", "t", 1.7, 31), ...
    localStudy("compression", "c", 1.7, 31)};
config = localConfig();
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
original = normalized;
mechanics.workflow.auditJointMaterialCharacterization(normalized, config);

verifyEqual(testCase, normalized.specimenCount, original.specimenCount);
verifyEqual(testCase, normalized.observationCount, original.observationCount);
for index = 1:numel(normalized.specimens)
    verifyEqual(testCase, normalized.specimens(index).Deformation, ...
        original.specimens(index).Deformation);
    verifyEqual(testCase, normalized.specimens(index).MeasuredStress, ...
        original.specimens(index).MeasuredStress);
end
end

function testInvalidSamplingFractionIsRejected(testCase)
studies = {
    localStudy("tension", "t", 2, 21), ...
    localStudy("compression", "c", 2, 21)};
config = localConfig();
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
auditConfig = mechanics.config.jointCharacterizationAuditConfig();
auditConfig.samplingFractions = [1; 0];
verifyError(testCase, @() ...
    mechanics.workflow.auditJointMaterialCharacterization( ...
    normalized, config, auditConfig), ...
    "mechanics:workflow:InvalidJointAuditSampling");
end

function testModeWeightWidthMustMatchModes(testCase)
studies = {
    localStudy("tension", "t", 2, 21), ...
    localStudy("compression", "c", 2, 21)};
config = localConfig();
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    studies, ["tension"; "compression"], config);
auditConfig = mechanics.config.jointCharacterizationAuditConfig();
auditConfig.modeWeightSets = [1, 1, 1];
verifyError(testCase, @() ...
    mechanics.workflow.auditJointMaterialCharacterization( ...
    normalized, config, auditConfig), ...
    "mechanics:workflow:InvalidJointAuditModeWeights");
end

function config = localConfig()
config = mechanics.config.jointMaterialCharacterizationConfig();
config.candidateModelNames = "neo-hookean";
config.selection.tieBreakOrder = "neo-hookean";
config.fitting.initialGuess = 1;
config.fitting.numberOfStarts = 3;
config.fitting.randomSeed = 4;
config.fitting.maxIterations = 1500;
config.fitting.maxFunctionEvaluations = 4000;
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
study.analysis.summary = table(specimenIds, ...
    repmat("processed", numel(specimenIds), 1), ...
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
stress = mechanics.models.evaluateModel( ...
    "neo-hookean", deformation, mu, context);
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
