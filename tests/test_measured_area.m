function tests = test_measured_area
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testTableImportReadsCurrentArea(testCase)
filename = string(tempname) + ".csv";
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
input = table([0; 10; 20], [0; 1; 2], [2; 1.8; 1.5], ...
    'VariableNames', {'Force','Displacement','CurrentArea_mm2'});
writetable(input, filename);
specimen = mechanics.io.readSpecimenTable(filename, ...
    mechanics.config.excelImportConfig());
verifyEqual(testCase, specimen.raw.currentArea, [2; 1.8; 1.5], ...
    "AbsTol", 1e-12);
verifyEqual(testCase, specimen.source.currentAreaColumn, "CurrentArea_mm2");
end

function testMeasuredAreaScaleIsApplied(testCase)
filename = string(tempname) + ".csv";
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
input = table([0; 10], [0; 1], [200; 180], ...
    'VariableNames', {'Force','Displacement','Area'});
writetable(input, filename);
config = mechanics.config.excelImportConfig();
config.currentAreaScale = 0.01;
specimen = mechanics.io.readSpecimenTable(filename, config);
verifyEqual(testCase, specimen.raw.currentArea, [2; 1.8], ...
    "AbsTol", 1e-12);
end

function testEndToEndMeasuredAreaStress(testCase)
filename = string(tempname) + ".csv";
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
input = table([0; 10; 20], [0; 1; 2], [2; 1.8; 1.5], ...
    'VariableNames', {'Force','Displacement','CurrentArea'});
writetable(input, filename);
specimen = mechanics.io.readSpecimenTable(filename, ...
    mechanics.config.excelImportConfig());
specimen.processingHistory = specimen.processingHistory;
geometry.initialLength = 10;
geometry.initialArea = 2;
config = mechanics.config.tensionConfig();
config.mechanics.stressMeasure = "true";
config.mechanics.areaEvolution = "measured-area";
config.analysis.summaryStrainRange = [0, 0.2];
processed = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, config);
verifyEqual(testCase, processed.processed.stress, ...
    [0; 10/1.8; 20/1.5], "AbsTol", 1e-12);
verifyEqual(testCase, processed.processed.currentArea, ...
    [2; 1.8; 1.5], "AbsTol", 1e-12);
end

function localDelete(filename)
if isfile(filename)
    delete(filename);
end
end
