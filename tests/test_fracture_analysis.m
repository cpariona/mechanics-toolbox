function tests = test_fracture_analysis
tests = functiontests(localfunctions);
end

function setupOnce(~)
testFile = mfilename("fullpath");
repositoryRoot = fileparts(fileparts(testFile));
addpath(repositoryRoot);
run(fullfile(repositoryRoot, "startup.m"));
end

function testPeakAndPostPeakMetrics(testCase)
specimen = localSpecimen( ...
    [0; 1; 2; 3; 1; 0], ...
    [0; 1; 2; 3; 4; 5]);
metrics = mechanics.analysis.computeFractureMetrics( ...
    specimen, mechanics.config.fractureAnalysisConfig());
verifyEqual(testCase, metrics.peakForce, 3);
verifyEqual(testCase, metrics.peakDisplacement, 3);
verifyEqual(testCase, metrics.postPeakDropFraction, 1);
verifyEqual(testCase, metrics.residualForceFraction, 0);
verifyFalse(testCase, isfield(metrics, "fractureDetected"));
verifyFalse(testCase, isfield(metrics, "completeFracture"));
verifyEqual(testCase, metrics.energyToPeak, 4.5, "AbsTol", 1e-12);
end

function testPeakStrainUsesPeakStressIndex(testCase)
specimen = localSpecimen( ...
    [0; 1; 2; 3; 1; 0], ...
    [0; 1; 2; 3; 4; 5]);
specimen.processed.stress = [0; 2; 5; 4];
specimen.processed.strain = [0; 0.1; 0.2; 0.3];
metrics = mechanics.analysis.computeFractureMetrics( ...
    specimen, mechanics.config.fractureAnalysisConfig());
verifyEqual(testCase, metrics.peakStress, 5);
verifyEqual(testCase, metrics.peakStressIndex, 3);
verifyEqual(testCase, metrics.peakStrain, 0.2, "AbsTol", 1e-12);
end

function testMetricsDoNotRequireSegmentation(testCase)
specimen = localSpecimen( ...
    [0; 1; 2; 3; 1; 0], ...
    [0; 1; 2; 3; 4; 5]);
specimen = rmfield(specimen, "segmentation");
metrics = mechanics.analysis.computeFractureMetrics( ...
    specimen, mechanics.config.fractureAnalysisConfig());
verifyEqual(testCase, metrics.peakForce, 3);
end

function testDisabledWorkflowDoesNotModifySpecimens(testCase)
analysis.records = localRecord("one");
config = mechanics.config.fractureAnalysisConfig();
config.enabled = false;
analysis = mechanics.workflow.addFractureMetrics(analysis, config);
verifyFalse(testCase, isfield(analysis.records(1).specimen, "fracture"));
verifyTrue(testCase, isempty(analysis.fractureSummary));
verifyFalse(testCase, analysis.fractureConfig.enabled);
end

function testWorkflowAddsPeakSummary(testCase)
analysis.records = [localRecord("one"), localRecord("two")];
analysis = mechanics.workflow.addFractureMetrics( ...
    analysis, mechanics.config.fractureAnalysisConfig());
verifyEqual(testCase, height(analysis.fractureSummary), 2);
verifyTrue(testCase, all(isfinite(analysis.fractureSummary.PeakForce)));
verifyFalse(testCase, ismember("CompleteFracture", ...
    string(analysis.fractureSummary.Properties.VariableNames)));
verifyTrue(testCase, isfield(analysis.records(1).specimen, "fracture"));
end

function testFractureExport(testCase)
analysis.records = localRecord("one");
analysis = mechanics.workflow.addFractureMetrics( ...
    analysis, mechanics.config.fractureAnalysisConfig());
folder = string(tempname);
cleanup = onCleanup(@() localRemoveFolder(folder)); %#ok<NASGU>
files = mechanics.io.exportFractureAnalysis(analysis, folder);
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
record.specimen = localSpecimen( ...
    [0; 1; 2; 3; 1; 0], ...
    [0; 1; 2; 3; 4; 5]);
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
specimen.segmentation.config.minimumPostPeakDropFraction = 0.20;
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end