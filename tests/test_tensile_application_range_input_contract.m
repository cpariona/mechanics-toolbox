function tests = test_tensile_application_range_input_contract
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testCompletedStudyIsRestrictedWithoutMutation(testCase)
study = localStudy(["s1"; "s2"], 41);
original = study;
config = localConfig([0.02, 0.08]);
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, config);

verifyEqual(testCase, normalized.requestedFitRange, [0.02, 0.08]);
verifyEqual(testCase, normalized.specimenCount, 2);
verifyEqual(testCase, normalized.excludedSpecimenCount, 0);
verifyEqual(testCase, normalized.specimens(1).IncludedIndices, (9:33)');
verifyEqual(testCase, normalized.specimens(1).Deformation, ...
    study.analysis.records(1).specimen.processed.strain(9:33));
verifyEqual(testCase, normalized.specimens(1).FittedRange, [0.02, 0.08], ...
    "AbsTol", 1e-12);
verifyEqual(testCase, normalized.specimens(1).AvailableRange, [0, 0.10], ...
    "AbsTol", 1e-12);
verifyEqual(testCase, study, original);
end

function testPopulationAnalysisAndIndividualFittingAreNotRequired(testCase)
study = localStudy(["s1"; "s2"], 31);
study = rmfield(study, "populationStatus");
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, localConfig([0, 0.05]));
verifyEqual(testCase, normalized.specimenCount, 2);
verifyFalse(testCase, isfield(study.analysis.records(1).specimen, ...
    "modelSelection"));
end

function testNonprocessedRecordsAreIgnored(testCase)
study = localStudy(["s1"; "s2"; "s3"], 31);
study.analysis.records(2).status = "failed";
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, localConfig([0, 0.05]));
verifyEqual(testCase, normalized.sourceStudyMetadata.recordCount, 3);
verifyEqual(testCase, normalized.sourceStudyMetadata.processedRecordCount, 2);
verifyEqual(testCase, normalized.specimenCount, 2);
verifyEqual(testCase, string({normalized.specimens.SourceSpecimenId})', ...
    ["s1"; "s3"]);
end

function testConfigUsesOneRangeVector(testCase)
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
verifyEqual(testCase, config.fitRange, [0, 0.30]);
verifyFalse(testCase, isfield(config, "minimum"));
verifyFalse(testCase, isfield(config, "maximum"));
verifyFalse(testCase, isfield(config, "fitting"));
verifyFalse(testCase, isfield(config, "export"));
end

function testRangeIsConfigurableAndNotHardcoded(testCase)
study = localStudy(["s1"; "s2"], 41);
shortRange = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, localConfig([0, 0.03]));
longRange = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, localConfig([0, 0.07]));
verifyLessThan(testCase, shortRange.observationCount, longRange.observationCount);
verifyEqual(testCase, max(shortRange.specimens(1).Deformation), 0.03, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, max(longRange.specimens(1).Deformation), 0.07, ...
    "AbsTol", 1e-12);
end

function testInvalidRangeIsRejected(testCase)
config = localConfig([0.05, 0.05]);
verifyError(testCase, @() mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    localStudy(["s1"; "s2"], 31), config), ...
    "mechanics:workflow:InvalidTensileApplicationFitRange");
end

function testInsufficientSpecimenObservationsAreRecorded(testCase)
study = localStudy(["s1"; "s2"; "s3"], 31);
study.analysis.records(2).specimen.processed.strain = linspace(0, 0.01, 4)';
study.analysis.records(2).specimen.processed.stress = ...
    2 .* study.analysis.records(2).specimen.processed.strain;
config = localConfig([0, 0.05]);
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, config);
verifyEqual(testCase, normalized.specimenCount, 2);
verifyEqual(testCase, normalized.excludedSpecimenCount, 1);
verifyEqual(testCase, normalized.excludedSpecimens.Reason, ...
    "insufficient-range-observations");
verifyEqual(testCase, normalized.excludedSpecimens.SourceSpecimenId, "s2");
end

function testTooFewRetainedSpecimensAreRejected(testCase)
study = localStudy(["s1"; "s2"], 5);
config = localConfig([0, 0.05]);
verifyError(testCase, @() mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, config), ...
    "mechanics:workflow:InsufficientTensileApplicationRangeSpecimens");
end

function testRequestedMaximumCanBeRequired(testCase)
study = localStudy(["s1"; "s2"; "s3"], 41);
study.analysis.records(2) = localRecord("s2", 41, 0.06);
config = localConfig([0, 0.08]);
config.requireRangeMaximum = true;
normalized = mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, config);
verifyEqual(testCase, normalized.specimenCount, 2);
verifyEqual(testCase, normalized.excludedSpecimens.Reason, ...
    "requested-maximum-unavailable");
end

function testInconsistentUnitsAreRejected(testCase)
study = localStudy(["s1"; "s2"], 31);
study.analysis.records(2).specimen.processed.units.stress = "kPa";
verifyError(testCase, @() mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, localConfig([0, 0.05])), ...
    "mechanics:workflow:InconsistentTensileApplicationRangeMetadata");
end

function testIncompatibleMeasureIsRejected(testCase)
study = localStudy(["s1"; "s2"], 31);
study.analysis.records(1).specimen.processed.mechanicsConfig.strainMeasure = "true";
verifyError(testCase, @() mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, localConfig([0, 0.05])), ...
    "mechanics:workflow:IncompatibleTensileApplicationRangeMeasure");
end

function testNonfiniteObservationsAreRejected(testCase)
study = localStudy(["s1"; "s2"], 31);
study.analysis.records(1).specimen.processed.stress(5) = NaN;
verifyError(testCase, @() mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, localConfig([0, 0.05])), ...
    "mechanics:workflow:NonfiniteTensileApplicationRangeObservations");
end

function testMaterialNegativeTensionIsRejected(testCase)
study = localStudy(["s1"; "s2"], 31);
study.analysis.records(1).specimen.processed.stress(1) = -0.1;
verifyError(testCase, @() mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    study, localConfig([0, 0.05])), ...
    "mechanics:workflow:InvalidTensileApplicationRangeSign");
end

function testRegisteredUniqueCandidatesAreRequired(testCase)
config = localConfig([0, 0.05]);
config.candidateModelNames = ["neo-hookean"; "neo-hookean"];
verifyError(testCase, @() mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    localStudy(["s1"; "s2"], 31), config), ...
    "mechanics:workflow:InvalidTensileApplicationRangeCandidateModels");

config = localConfig([0, 0.05]);
config.candidateModelNames = "not-a-model";
verifyError(testCase, @() mechanics.workflow.normalizeTensileApplicationRangeStudy( ...
    localStudy(["s1"; "s2"], 31), config), ...
    "mechanics:models:UnknownModel");
end

function config = localConfig(fitRange)
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.fitRange = fitRange;
config.minimumObservationsPerSpecimen = 6;
config.minimumSpecimens = 2;
end

function study = localStudy(specimenIds, pointCount)
specimenIds = string(specimenIds(:));
records = repmat(localRecord("", pointCount, 0.10), numel(specimenIds), 1);
for index = 1:numel(specimenIds)
    records(index) = localRecord(specimenIds(index), pointCount, 0.10);
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

function record = localRecord(specimenId, pointCount, maximumStrain)
strain = linspace(0, maximumStrain, pointCount)';
stress = 2 .* strain;
specimen.id = string(specimenId);
specimen.processed.strain = strain;
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
