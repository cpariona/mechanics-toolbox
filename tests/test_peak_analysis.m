function tests = test_peak_analysis
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testPeakAndPostPeakMetrics(testCase)
specimen = localSpecimen([0;1;2;3;1;0], [0;1;2;3;4;5]);
metrics = mechanics.analysis.computePeakMetrics( ...
    specimen, mechanics.config.peakAnalysisConfig());
verifyEqual(testCase, metrics.peakForce, 3);
verifyEqual(testCase, metrics.peakDisplacement, 3);
verifyEqual(testCase, metrics.postPeakDropFraction, 1);
verifyEqual(testCase, metrics.residualForceFraction, 0);
verifyEqual(testCase, metrics.energyToPeak, 4.5, "AbsTol", 1e-12);
end

function testPeakStrainUsesPeakStressIndex(testCase)
specimen = localSpecimen([0;1;2;3;1;0], [0;1;2;3;4;5]);
specimen.processed.stress = [0;2;5;4];
specimen.processed.strain = [0;0.1;0.2;0.3];
metrics = mechanics.analysis.computePeakMetrics( ...
    specimen, mechanics.config.peakAnalysisConfig());
verifyEqual(testCase, metrics.peakStress, 5);
verifyEqual(testCase, metrics.peakStressIndex, 3);
verifyEqual(testCase, metrics.peakStrain, 0.2, "AbsTol", 1e-12);
end

function testMetricsDoNotRequireSegmentation(testCase)
specimen = localSpecimen([0;1;2;3;1;0], [0;1;2;3;4;5]);
specimen = rmfield(specimen, "segmentation");
metrics = mechanics.analysis.computePeakMetrics( ...
    specimen, mechanics.config.peakAnalysisConfig());
verifyEqual(testCase, metrics.peakForce, 3);
end

function testDisabledWorkflowDoesNotModifySpecimens(testCase)
analysis.records = localRecord("one");
config = mechanics.config.peakAnalysisConfig();
config.enabled = false;
analysis = mechanics.workflow.addPeakMetrics(analysis, config);
verifyFalse(testCase, isfield(analysis.records(1).specimen, "peakMetrics"));
verifyTrue(testCase, isempty(analysis.peakSummary));
verifyFalse(testCase, analysis.peakAnalysisConfig.enabled);
end

function testWorkflowAddsPeakSummary(testCase)
analysis.records = [localRecord("one"), localRecord("two")];
analysis = mechanics.workflow.addPeakMetrics( ...
    analysis, mechanics.config.peakAnalysisConfig());
verifyEqual(testCase, height(analysis.peakSummary), 2);
verifyTrue(testCase, all(isfinite(analysis.peakSummary.PeakForce)));
verifyTrue(testCase, isfield(analysis.records(1).specimen, "peakMetrics"));
end

function testPeakExport(testCase)
analysis.records = localRecord("one");
analysis = mechanics.workflow.addPeakMetrics( ...
    analysis, mechanics.config.peakAnalysisConfig());
folder = string(tempname);
cleanup = onCleanup(@() localRemoveFolder(folder)); %#ok<NASGU>
files = mechanics.io.exportPeakAnalysis(analysis, folder);
verifyTrue(testCase, isfile(files.summary));
verifyTrue(testCase, isfile(files.analysis));
end

function record = localRecord(id)
record.index = 1;
record.specimenId = string(id);
record.sheetName = string(id);
record.status = "processed";
record.segmentation = struct();
record.quality = struct();
record.specimen = localSpecimen([0;1;2;3;1;0], [0;1;2;3;4;5]);
record.errorIdentifier = "";
record.errorMessage = "";
end

function specimen = localSpecimen(force, displacement)
specimen.id = "sample";
specimen.raw.force = force;
specimen.raw.displacement = displacement;
specimen.geometry.initialArea = 2;
specimen.geometry.initialLength = 10;
specimen.processed.stress = force(1:4) ./ 2;
specimen.processed.strain = displacement(1:4) ./ 10;
specimen.segmentation = struct();
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
