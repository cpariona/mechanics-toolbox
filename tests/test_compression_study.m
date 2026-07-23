function tests = test_compression_study
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testLastCompleteLoadingCycleIsSelected(testCase)
[displacement, force] = localThreeCycles();
raw.displacement = displacement;
raw.force = force;
config = mechanics.config.compressionStudyConfig();
config.cycle.smoothingFrameLength = 1;
result = mechanics.segmentation.selectCompressionCycle(raw, config.cycle);
verifyEqual(testCase, result.cycleCount, 3);
verifyEqual(testCase, result.selectedCycleIndex, 3);
verifyEqual(testCase, result.selectedRaw.displacement(1), 0, "AbsTol", 1e-12);
verifyEqual(testCase, result.selectedRaw.displacement(end), 1, "AbsTol", 1e-12);
verifyEqual(testCase, result.branch, "loading");
end

function testCompressionStudyProcessesLastCycle(testCase)
[displacement, force] = localThreeCycles();
filename = string(tempname) + ".csv";
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
writetable(table(force, displacement, ...
    'VariableNames', {'Force','Displacement'}), filename);

config = mechanics.config.compressionStudyConfig();
config.geometry.initialLength = 10;
config.geometry.initialArea = 2;
config.cycle.smoothingFrameLength = 1;
config.processing.analysis.summaryStrainRange = [0, 0.1];
study = mechanics.workflow.runCompressionStudy(filename, config);

verifyEqual(testCase, study.cycle.selectedCycleIndex, 3);
verifyEqual(testCase, study.specimen.processed.strain(end), 0.1, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, study.specimen.processed.stress(end), 2.5, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, study.specimen.testType, "compression");
verifyEqual(testCase, study.cycleMetrics.loadingEnergy, 2.5, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, study.cycleMetrics.recoveredEnergy, 2.5, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, study.cycleMetrics.hysteresisEnergy, 0, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, study.cycleMetrics.hysteresisFraction, 0, ...
    "AbsTol", 1e-12);
end

function testCompressionStudyExport(testCase)
[displacement, force] = localThreeCycles();
filename = string(tempname) + ".csv";
cleanupFile = onCleanup(@() localDelete(filename)); %#ok<NASGU>
writetable(table(force, displacement, ...
    'VariableNames', {'Force','Displacement'}), filename);

folder = string(tempname);
cleanupFolder = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
config = mechanics.config.compressionStudyConfig();
config.geometry.initialLength = 10;
config.geometry.initialArea = 2;
config.cycle.smoothingFrameLength = 1;
config.processing.analysis.summaryStrainRange = [0, 0.1];
config.export.enabled = true;
config.export.outputFolder = folder;
config.export.report.figureResolution = 72;
study = mechanics.workflow.runCompressionStudy(filename, config);

verifyTrue(testCase, isfile(study.outputFiles.processed));
verifyTrue(testCase, isfile(study.outputFiles.metrics));
verifyTrue(testCase, isfile(study.outputFiles.study));
verifyTrue(testCase, isfile(study.outputFiles.reportReport));
verifyTrue(testCase, isfile(study.outputFiles.reportCycleOverview));
verifyTrue(testCase, isfile(study.outputFiles.reportSelectedBranch));
verifyTrue(testCase, isfile(study.outputFiles.reportTangentModulus));
end

function testDecreasingInstrumentSignalsCanBeNormalized(testCase)
[displacement, force] = localThreeCycles();
raw.displacement = -displacement;
raw.force = -force;
config = mechanics.config.compressionStudyConfig();
config.cycle.loadingDirection = "decreasing";
config.cycle.smoothingFrameLength = 1;
result = mechanics.segmentation.selectCompressionCycle(raw, config.cycle);
verifyEqual(testCase, result.cycleCount, 3);
verifyLessThan(testCase, result.selectedRaw.displacement(end), ...
    result.selectedRaw.displacement(1));
end

function [displacement, force] = localThreeCycles()
loading = linspace(0, 1, 11)';
unloading = linspace(0.9, 0, 10)';
oneCycle = [loading; unloading];
displacement = [oneCycle; oneCycle; oneCycle];
force = 5 .* displacement;
end

function localDelete(filename)
if isfile(filename)
    delete(filename);
end
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end