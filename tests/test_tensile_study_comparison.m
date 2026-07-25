function tests = test_tensile_study_comparison
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testCompletedStudiesAreCompared(testCase)
studies = [localStudy("shared", 2), localStudy("shared", 4)];
config = localConfig();
comparison = mechanics.workflow.compareTensileStudies( ...
    studies, ["ECOFLEX 00-20", "ECOFLEX 00-50"], config);

verifyEqual(testCase, comparison.groupLabels, ...
    ["ECOFLEX 00-20"; "ECOFLEX 00-50"]);
verifyEqual(testCase, comparison.studySummaries.ProcessedCount, [2; 2]);
verifyEqual(testCase, comparison.groupComparison.groups(1).specimenCount, 2);
verifyEqual(testCase, comparison.groupComparison.groups(2).specimenCount, 2);
verifyEqual(testCase, ...
    comparison.groupComparison.curveComparison.meanDifference(end), ...
    -2, 'AbsTol', 1e-12);
verifyTrue(testCase, comparison.compatibility.measuresMatch);
verifyTrue(testCase, comparison.compatibility.unitsMatch);
end

function testDuplicateOriginalIdsAreNamespaced(testCase)
studies = [localStudy("specimen", 2), localStudy("specimen", 4)];
comparison = mechanics.workflow.compareTensileStudies( ...
    studies, ["first", "second"], localConfig());

ids = string(comparison.groupComparison.groups(1).population.specimenIds);
verifyTrue(testCase, all(startsWith(ids, "study-1::")));
verifyEqual(testCase, studies(1).analysis.summary.SpecimenId, ...
    ["specimen-1"; "specimen-2"]);
end

function testMeasureMismatchIsRejected(testCase)
studies = [localStudy("a", 2), localStudy("b", 4)];
studies(2).config.datasetAnalysis.processingConfig.mechanics.stressMeasure = ...
    "true";
verifyError(testCase, @() mechanics.workflow.compareTensileStudies( ...
    studies, ["first", "second"], localConfig()), ...
    "mechanics:workflow:IncompatibleStudyMeasures");
end

function testLabelCountMismatchIsRejected(testCase)
studies = [localStudy("a", 2), localStudy("b", 4)];
verifyError(testCase, @() mechanics.workflow.compareTensileStudies( ...
    studies, "only-one", localConfig()), ...
    "mechanics:workflow:StudyLabelCountMismatch");
end

function config = localConfig()
config = mechanics.config.tensileStudyComparisonConfig();
config.groupComparison.minimumSpecimensPerGroup = 2;
config.groupComparison.populationConfig.minimumSpecimens = 2;
config.groupComparison.populationConfig.bootstrap.enabled = false;
config.groupComparison.populationConfig.strainGridPointCount = 21;
config.groupComparison.bootstrap.enabled = false;
config.groupComparison.export.enabled = false;
end

function study = localStudy(prefix, slope)
ids = prefix + ["-1"; "-2"];
records = repmat(localRecord("", slope), 2, 1);
for index = 1:2
    records(index) = localRecord(ids(index), slope);
end
study.analysis.records = records;
study.analysis.summary = table(ids, repmat("processed", 2, 1), ...
    ones(2,1), repmat(slope,2,1), repmat(slope,2,1), ...
    'VariableNames', {'SpecimenId','Status','MaximumStrain', ...
    'MaximumStress','MedianTangentModulus'});
study.config = mechanics.config.tensileStudyConfig();
study.populationStatus = "completed";
study.sourceFiles = strings(0,1);
study.createdAt = datetime("now");
end

function record = localRecord(id, slope)
strain = linspace(0,1,21)';
specimen.id = string(id);
specimen.processed.strain = strain;
specimen.processed.stress = slope .* strain;
specimen.processed.units.strain = "1";
specimen.processed.units.stress = "MPa";
record.index = 1;
record.specimenId = string(id);
record.sheetName = string(id);
record.status = "processed";
record.quality = struct();
record.specimen = specimen;
record.errorIdentifier = "";
record.errorMessage = "";
record.group = "";
end
