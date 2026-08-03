function tests = test_tensile_application_range_audit
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testRangeSensitivityRunsConfiguredMaximumsWithoutMutation(testCase)
config = localConfig();
study = localStudy("tension", ["t1"; "t2"], 0.4, 61);
original = study;
audit = mechanics.workflow.auditTensileApplicationRangeSensitivity(study, config);
verifyEqual(testCase, audit.maximumDeformations, [0.10; 0.20; 0.30]);
verifyEqual(testCase, audit.completedScenarioCount, 3);
verifyEqual(testCase, audit.failedScenarioCount, 0);
verifyEqual(testCase, audit.scenarioSummary.SelectedModelName, ...
    repmat("neo-hookean", 3, 1));
verifyEqual(testCase, audit.scenarioSummary.Mu0, repmat(0.4, 3, 1), ...
    "AbsTol", 2e-3);
verifyEqual(testCase, study, original);
end

function testInvalidSensitivityMaximumsAreRejected(testCase)
config = localConfig();
config.rangeSensitivity.maximumDeformations = [0.2; 0.2];
verifyError(testCase, @() mechanics.workflow.auditTensileApplicationRangeSensitivity( ...
    localStudy("tension", ["t1"; "t2"], 0.4, 41), config), ...
    "mechanics:workflow:InvalidTensileApplicationRangeSensitivityMaximums");
end

function testCompressionValidationUsesFixedParameters(testCase)
config = localConfig();
selection = localSelection(0.4);
compressionStudy = localStudy("compression", ["c1"; "c2"], 0.4, 51);
validation = mechanics.workflow.validateTensileApplicationRangeCompression( ...
    selection, compressionStudy, config);
verifyFalse(testCase, validation.refitPerformed);
verifyEqual(testCase, validation.modelName, "neo-hookean");
verifyEqual(testCase, validation.parameters, 0.4, "AbsTol", 1e-12);
verifyLessThan(testCase, validation.meanRMSE, 1e-10);
verifyEqual(testCase, numel(validation.specimens), 2);
verifyTrue(testCase, all(arrayfun(@(x) isfield(x, "PredictedStress"), ...
    validation.specimens)));
end

function testCompressionValidationMinimumIsEnforced(testCase)
config = localConfig();
config.compressionValidation.minimumSpecimens = 2;
verifyError(testCase, @() mechanics.workflow.validateTensileApplicationRangeCompression( ...
    localSelection(0.4), localStudy("compression", "c1", 0.4, 31), config), ...
    "mechanics:workflow:InsufficientCompressionValidationSpecimens");
end

function config = localConfig()
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.fitRange = [0, 0.30];
config.rangeSensitivity.maximumDeformations = [0.10; 0.20; 0.30];
config.candidateModelNames = "neo-hookean";
config.selection.tieBreakOrder = "neo-hookean";
config.minimumObservationsPerSpecimen = 8;
config.minimumSpecimens = 2;
config.fitting.numberOfStarts = 3;
config.fitting.randomSeed = 7;
end

function selection = localSelection(mu)
selection.selectedModelName = "neo-hookean";
selection.selectedFit.modelName = "neo-hookean";
selection.selectedFit.parameters = mu;
selection.selectedFit.objective = 0;
selection.referenceProperties.modelName = "neo-hookean";
selection.referenceProperties.names = "mu0";
selection.referenceProperties.values = mu;
end

function study = localStudy(mode, specimenIds, mu, pointCount)
specimenIds = string(specimenIds(:));
records = repmat(localRecord(mode, "", mu, pointCount), numel(specimenIds), 1);
for index = 1:numel(specimenIds)
    records(index) = localRecord(mode, specimenIds(index), mu, pointCount);
    records(index).index = index;
end
study.sourceFile = "synthetic.xlsx";
study.sourceFiles = "synthetic.xlsx";
study.analysis.records = records;
study.populationStatus = "completed";
study.config = struct();
study.provenance.inputType = "synthetic";
study.createdAt = datetime(2026, 8, 2);
end

function record = localRecord(mode, specimenId, mu, pointCount)
if mode == "tension"
    deformation = linspace(0, 0.30, pointCount)';
else
    deformation = linspace(0, -0.25, pointCount)';
end
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
stress = mechanics.models.evaluateModel("neo-hookean", deformation, mu, context);
specimen.id = string(specimenId);
specimen.processed.strain = deformation;
specimen.processed.stress = stress;
specimen.processed.units.strain = "1";
specimen.processed.units.stress = "MPa";
specimen.processed.mechanicsConfig.strainMeasure = "engineering";
specimen.processed.mechanicsConfig.stressMeasure = "engineering";
record.index = 1;
record.specimenId = string(specimenId);
record.sheetName = "Sheet-" + specimenId;
record.status = "processed";
record.specimen = specimen;
record.errorIdentifier = "";
record.errorMessage = "";
end
