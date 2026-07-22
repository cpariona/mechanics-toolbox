function tests = test_dataset_analysis
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testGoodSpecimenPassesQuality(testCase)
specimen = localSpecimen("good", (0:20)', (0:20)');

config = mechanics.config.datasetAnalysisConfig();
quality = mechanics.quality.assessSpecimenQuality( ...
    specimen, config.quality);

verifyTrue(testCase, quality.passed);
verifyEqual(testCase, quality.finiteObservationCount, 21);
verifyEqual(testCase, quality.displacementReversalFraction, 0);
end

function testReversalCanFailQuality(testCase)
displacement = [0; 1; 2; 1.5; (3:20)'];
force = (0:numel(displacement)-1)';
specimen = localSpecimen("reversal", displacement, force);

config = mechanics.config.datasetAnalysisConfig();
config.quality.minimumObservations = 5;
config.quality.maximumDisplacementReversalFraction = 0;

quality = mechanics.quality.assessSpecimenQuality( ...
    specimen, config.quality);

verifyFalse(testCase, quality.passed);
verifyTrue(testCase, ...
    ismember("displacementReversals", quality.failedChecks));
end

function testDatasetAnalysisProcessesSpecimens(testCase)
dataset.specimens = [ ...
    localSpecimen("one", (0:20)', 2 .* (0:20)'), ...
    localSpecimen("two", (0:20)', 4 .* (0:20)')];

config = mechanics.config.datasetAnalysisConfig();
analysis = mechanics.workflow.analyzeExtractedDataset(dataset, config);

verifyEqual(testCase, analysis.summary.Status, ...
    ["processed"; "processed"]);
verifyEqual(testCase, analysis.summary.MaximumStress, ...
    [20; 40], "AbsTol", 1e-12);
end

function testQualityFailureIsRecorded(testCase)
dataset.specimens = localSpecimen( ...
    "short", [0; 1; 2], [0; 1; 2]);

config = mechanics.config.datasetAnalysisConfig();
config.quality.minimumObservations = 10;

analysis = mechanics.workflow.analyzeExtractedDataset(dataset, config);

verifyEqual(testCase, analysis.summary.Status, "quality-failed");
verifyFalse(testCase, analysis.summary.QualityPassed);
verifyTrue(testCase, contains( ...
    analysis.summary.FailedQualityChecks, ...
    "minimumObservations"));
end

function testProcessingFailureDoesNotStopDataset(testCase)
good = localSpecimen("good", (0:20)', (0:20)');
bad = localSpecimen("bad", (0:20)', (0:20)');
bad.geometry.initialLength = NaN;

dataset.specimens = [good, bad];

config = mechanics.config.datasetAnalysisConfig();
config.continueOnError = true;

analysis = mechanics.workflow.analyzeExtractedDataset(dataset, config);

verifyEqual(testCase, analysis.summary.Status, ...
    ["processed"; "failed"]);
verifyEqual(testCase, analysis.summary.ErrorIdentifier(2), ...
    "mechanics:workflow:MissingInitialLength");
end

function testOptionalFitting(testCase)
strain = linspace(0, 0.8, 80)';
force = 0.2 .* (1 + strain - (1 + strain).^(-2)) .* 2;
displacement = strain .* 10;

dataset.specimens = localSpecimen( ...
    "fit", displacement, force);

config = mechanics.config.datasetAnalysisConfig();
config.fitting.enabled = true;
config.fitting.modelNames = "neo-hookean";
config.fitting.selectionConfig.windowFractions = [0.5, 0.75, 1];
config.fitting.selectionConfig.minimumObservations = 15;

analysis = mechanics.workflow.analyzeExtractedDataset(dataset, config);

verifyEqual(testCase, analysis.summary.Status, "processed");
verifyEqual(testCase, analysis.summary.BestModel, "neo-hookean");
verifyGreaterThan(testCase, analysis.summary.BestModelRSquared, 0.999);
end

function testDatasetExport(testCase)
folder = string(tempname);
cleanup = onCleanup(@() localRemoveFolder(folder));

analysis.summary = table("sample", "processed", ...
    'VariableNames', {'SpecimenId','Status'});

files = mechanics.io.exportDatasetAnalysis(analysis, folder);

verifyTrue(testCase, isfile(files.summary));
verifyTrue(testCase, isfile(files.analysis));
end

function specimen = localSpecimen(id, displacement, force)
specimen.id = string(id);
specimen.sheetName = string(id);
specimen.testType = "tension";
specimen.raw.displacement = displacement(:);
specimen.raw.force = force(:);
specimen.geometry.initialLength = 10;
specimen.geometry.initialArea = 2;
specimen.source.filename = "synthetic";
specimen.metadata = struct();
specimen.processingHistory = struct( ...
    "timestamp", datetime("now"), ...
    "step", "synthetic", ...
    "description", "synthetic specimen");
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
