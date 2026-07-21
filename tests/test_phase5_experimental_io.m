function tests = test_phase5_experimental_io
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testCsvImportWithAliases(testCase)
filename = string(tempname) + ".csv";
cleanup = onCleanup(@() localDelete(filename));

data = table( ...
    (0:4)', ...
    (0:4)' .* 2, ...
    (0:4)' .* 0.1, ...
    'VariableNames', {'Time_s', 'Load_N', 'Extension_mm'});
writetable(data, filename);

config = mechanics.config.excelImportConfig();
specimen = mechanics.io.readSpecimenTable(filename, config);

verifyEqual(testCase, specimen.raw.force, data.Load_N, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, specimen.raw.displacement, data.Extension_mm, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, specimen.raw.time, data.Time_s, ...
    "AbsTol", 1e-12);
verifyEqual(testCase, specimen.source.forceColumn, "Load_N");
verifyEqual(testCase, numel(specimen.processingHistory), 1);
end

function testImportScaling(testCase)
filename = string(tempname) + ".csv";
cleanup = onCleanup(@() localDelete(filename));

data = table([0; 1000], [0; 2], ...
    'VariableNames', {'Force', 'Displacement'});
writetable(data, filename);

config = mechanics.config.excelImportConfig();
config.forceScale = 1e-3;
config.displacementScale = 10;

specimen = mechanics.io.readSpecimenTable(filename, config);

verifyEqual(testCase, specimen.raw.force, [0; 1]);
verifyEqual(testCase, specimen.raw.displacement, [0; 20]);
end

function testMissingRequiredColumnRejected(testCase)
filename = string(tempname) + ".csv";
cleanup = onCleanup(@() localDelete(filename));

data = table([0; 1], 'VariableNames', {'Force'});
writetable(data, filename);

verifyError(testCase, @() mechanics.io.readSpecimenTable( ...
    filename, mechanics.config.excelImportConfig()), ...
    "mechanics:io:MissingColumn");
end

function testWorkflowPreservesRawData(testCase)
specimen.id = "synthetic";
specimen.raw.force = [0; 10; 20];
specimen.raw.displacement = [0; 1; 2];
specimen.processingHistory = struct( ...
    "timestamp", datetime("now"), ...
    "step", "import", ...
    "description", "synthetic");

originalForce = specimen.raw.force;
originalDisplacement = specimen.raw.displacement;

geometry.initialLength = 10;
geometry.initialArea = 2;
config = mechanics.config.tensionConfig();

processed = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, config);

verifyEqual(testCase, processed.raw.force, originalForce);
verifyEqual(testCase, processed.raw.displacement, originalDisplacement);
verifyEqual(testCase, processed.processed.strain, [0; 0.1; 0.2]);
verifyEqual(testCase, processed.processed.stress, [0; 5; 10]);
verifyEqual(testCase, numel(processed.processingHistory), 2);
end

function testIdenticalCurveComparison(testCase)
curve.strain = linspace(0, 1, 20)';
curve.stress = 2 .* curve.strain;

comparison = mechanics.validation.compareCurves(curve, curve, 1e-12);

verifyTrue(testCase, comparison.passed);
verifyEqual(testCase, comparison.rmse, 0, "AbsTol", 1e-12);
end

function testDifferentCurveComparison(testCase)
reference.strain = linspace(0, 1, 20)';
reference.stress = 2 .* reference.strain;
candidate.strain = reference.strain;
candidate.stress = 2.2 .* candidate.strain;

comparison = mechanics.validation.compareCurves( ...
    reference, candidate, 0.01);

verifyFalse(testCase, comparison.passed);
verifyGreaterThan(testCase, comparison.normalizedRmse, 0.01);
end

function testExportCreatesFiles(testCase)
folder = string(tempname);
cleanup = onCleanup(@() localRemoveFolder(folder));

specimen.id = "specimen 1";
specimen.processed.strain = [0; 0.1];
specimen.processed.stress = [0; 2];
specimen.processingHistory = struct( ...
    "timestamp", datetime("now"), ...
    "step", "test", ...
    "description", "test export");

outputFiles = mechanics.io.exportSpecimenResults(specimen, folder);

verifyTrue(testCase, isfile(outputFiles.curve));
verifyTrue(testCase, isfile(outputFiles.summary));
verifyTrue(testCase, isfile(outputFiles.history));
end

function localDelete(filename)
if isfile(filename)
    delete(filename);
end
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
