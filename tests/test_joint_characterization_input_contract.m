function tests = test_joint_characterization_input_contract
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testIndependentUnpairedStudiesAreNormalized(testCase)
tension = localStudy("tension", ["shared"; "tension-only"], 1);
compression = localStudy("compression", ["shared"; "c2"; "c3"], 1);
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {tension, compression}, ["tension"; "compression"]);

verifyEqual(testCase, normalized.modeNames, ["tension"; "compression"]);
verifyEqual(testCase, normalized.modeWeights, [0.5; 0.5], "AbsTol", 1e-12);
verifyEqual(testCase, normalized.modeSummary.SpecimenCount, [2; 3]);
verifyEqual(testCase, normalized.specimenCount, 5);
verifyEqual(testCase, normalized.observationCount, 55);
verifyEqual(testCase, normalized.specimens(1).OriginalSpecimenId, "shared");
verifyEqual(testCase, normalized.specimens(3).OriginalSpecimenId, "shared");
verifyNotEqual(testCase, normalized.specimens(1).SpecimenId, ...
    normalized.specimens(3).SpecimenId);
verifyTrue(testCase, startsWith(normalized.specimens(1).SpecimenId, "tension::"));
verifyTrue(testCase, startsWith(normalized.specimens(3).SpecimenId, "compression::"));
verifyGreaterThanOrEqual(testCase, min(normalized.specimens(1).Deformation), 0);
verifyLessThanOrEqual(testCase, max(normalized.specimens(3).Deformation), 0);
verifyEqual(testCase, normalized.specimens(1).Context.deformationMeasure, ...
    "engineering-strain");
verifyEqual(testCase, normalized.specimens(1).Context.stressMeasure, "nominal");
end

function testDefaultCandidatesUseExplicitThirdOrderYeoh(testCase)
config = mechanics.config.jointMaterialCharacterizationConfig();
verifyEqual(testCase, config.candidateModelNames, ...
    ["neo-hookean"; "mooney-rivlin"; "yeoh-third-order"]);
verifyFalse(testCase, any(config.candidateModelNames == "yeoh"));
verifyEqual(testCase, config.selection.tieBreakOrder, ...
    config.candidateModelNames);
end

function testConfiguredModeWeightsAreNormalized(testCase)
config = mechanics.config.jointMaterialCharacterizationConfig();
config.modeWeights = [3; 1];
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {localStudy("tension", "t1", 1), ...
     localStudy("compression", "c1", 1)}, ...
    ["tension"; "compression"], config);
verifyEqual(testCase, normalized.modeWeights, [0.75; 0.25], "AbsTol", 1e-12);
end

function testTrueMeasuresMapToModelContext(testCase)
tension = localStudy("tension", "t1", 1);
for index = 1:numel(tension.analysis.records)
    mechanicsConfig = tension.analysis.records(index).specimen.processed.mechanicsConfig;
    mechanicsConfig.strainMeasure = "true";
    mechanicsConfig.stressMeasure = "true";
    tension.analysis.records(index).specimen.processed.mechanicsConfig = mechanicsConfig;
end
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {tension}, "tension", localSingleModeConfig("tension"));
verifyEqual(testCase, normalized.specimens.Context.deformationMeasure, "true-strain");
verifyEqual(testCase, normalized.specimens.Context.stressMeasure, "cauchy");
end

function testUnsupportedModeIsRejected(testCase)
verifyError(testCase, @() mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {localStudy("tension", "t1", 1)}, "biaxial", ...
    localSingleModeConfig("biaxial")), ...
    "mechanics:workflow:UnsupportedJointCharacterizationMode");
end

function testCompressionSignViolationIsRejected(testCase)
study = localStudy("compression", "c1", 1);
study.analysis.records(1).specimen.processed.strain = ...
    abs(study.analysis.records(1).specimen.processed.strain);
verifyError(testCase, @() mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {study}, "compression", localSingleModeConfig("compression")), ...
    "mechanics:workflow:InvalidJointModeSign");
end

function testSmallOppositeStressNoiseIsPreserved(testCase)
study = localStudy("tension", "t1", 1);
stress = study.analysis.records(1).specimen.processed.stress;
stress(1) = -5e-5;
study.analysis.records(1).specimen.processed.stress = stress;
normalized = mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {study}, "tension", localSingleModeConfig("tension"));
verifyEqual(testCase, normalized.specimens.MeasuredStress(1), -5e-5, ...
    "AbsTol", eps);
end

function testMaterialOppositeStressIsRejected(testCase)
study = localStudy("tension", "t1", 1);
stress = study.analysis.records(1).specimen.processed.stress;
stress(1) = -0.01;
study.analysis.records(1).specimen.processed.stress = stress;
verifyError(testCase, @() mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {study}, "tension", localSingleModeConfig("tension")), ...
    "mechanics:workflow:InvalidJointModeSign");
end

function testInvalidSignToleranceIsRejected(testCase)
config = localSingleModeConfig("tension");
config.signTolerance.stressRelative = -1;
verifyError(testCase, @() mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {localStudy("tension", "t1", 1)}, "tension", config), ...
    "mechanics:workflow:InvalidJointSignTolerance");
end

function testCrossModeStressUnitMismatchIsRejected(testCase)
tension = localStudy("tension", "t1", 1);
compression = localStudy("compression", "c1", 1);
compression.analysis.records(1).specimen.processed.units.stress = "kPa";
verifyError(testCase, @() mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {tension, compression}, ["tension"; "compression"]), ...
    "mechanics:workflow:IncompatibleJointStressUnits");
end

function testIncompleteStudyIsRejected(testCase)
study = localStudy("tension", "t1", 1);
study.populationStatus = "insufficient-specimens";
verifyError(testCase, @() mechanics.workflow.normalizeJointCharacterizationStudies( ...
    {study}, "tension", localSingleModeConfig("tension")), ...
    "mechanics:workflow:IncompleteJointStudy");
end

function config = localSingleModeConfig(modeName)
config = mechanics.config.jointMaterialCharacterizationConfig();
config.modeNames = string(modeName);
config.modeWeights = 1;
end

function study = localStudy(modeName, specimenIds, slope)
specimenIds = string(specimenIds(:));
records = repmat(localRecord("", modeName, slope), numel(specimenIds), 1);
for index = 1:numel(specimenIds)
    records(index) = localRecord(specimenIds(index), modeName, slope);
end
study.analysis.records = records;
study.analysis.summary = table(specimenIds, repmat("processed", numel(specimenIds), 1), ...
    'VariableNames', {'SpecimenId','Status'});
study.populationStatus = "completed";
study.config = struct();
study.createdAt = datetime("now");
end

function record = localRecord(specimenId, modeName, slope)
strain = linspace(0, 0.1, 11)';
if modeName == "compression"
    strain = -strain;
end
stress = slope .* strain;
specimen.id = string(specimenId);
specimen.testType = string(modeName);
specimen.processed.strain = strain;
specimen.processed.stress = stress;
specimen.processed.units.strain = "1";
specimen.processed.units.stress = "MPa";
specimen.processed.mechanicsConfig.strainMeasure = "engineering";
specimen.processed.mechanicsConfig.stressMeasure = "engineering";
record.index = 1;
record.specimenId = string(specimenId);
record.status = "processed";
record.specimen = specimen;
record.group = "";
record.errorIdentifier = "";
record.errorMessage = "";
end
