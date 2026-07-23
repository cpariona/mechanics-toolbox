function tests = test_pipeline_refinements
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testPreloadThresholdDefinesMechanicalZero(testCase)
config = mechanics.config.tensionConfig();
config.preprocessing.zeroReference.method = "preload-threshold";
config.preprocessing.zeroReference.preloadForce = 0.1;
config.preprocessing.zeroReference.sustainedPoints = 2;
raw.force = [0; 0.05; 0.1; 0.2; 0.3];
raw.displacement = [0; 0.1; 0.2; 0.3; 0.4];
curve = mechanics.preprocessing.prepareCurve(raw, config.preprocessing);
verifyEqual(testCase, curve.force, [0; 0.1; 0.2], "AbsTol", 1e-12);
verifyEqual(testCase, curve.displacement, [0; 0.1; 0.2], "AbsTol", 1e-12);
verifyEqual(testCase, curve.zeroReference.inputIndex, 3);
verifyEqual(testCase, curve.zeroReference.originalIndex, 3);
end

function testManualZeroIndex(testCase)
config = mechanics.config.tensionConfig();
config.preprocessing.zeroReference.method = "manual-index";
config.preprocessing.zeroReference.manualIndex = 2;
raw.force = [4; 5; 7];
raw.displacement = [1; 2; 4];
curve = mechanics.preprocessing.prepareCurve(raw, config.preprocessing);
verifyEqual(testCase, curve.force, [0; 2]);
verifyEqual(testCase, curve.displacement, [0; 2]);
end

function testLocalLinearTangentModulus(testCase)
config = mechanics.config.tensionConfig();
curve.strain = linspace(0, 0.3, 301)';
curve.stress = 7 .* curve.strain;
result = mechanics.analysis.computeTangentModulus(curve, config.analysis);
verifyEqual(testCase, result.medianModulus, 7, "AbsTol", 1e-10);
verifyEqual(testCase, result.summaryStrainRange, [0, 0.05]);
end

function testMedianPopulationCurve(testCase)
strain = linspace(0, 1, 21)';
specimens(1) = localProcessedSpecimen("one", strain, strain);
specimens(2) = localProcessedSpecimen("two", strain, 2 .* strain);
specimens(3) = localProcessedSpecimen("three", strain, 100 .* strain);
config = mechanics.config.populationAnalysisConfig();
config.centralStatistic = "median";
config.strainGridPointCount = 21;
config.bootstrap.enabled = false;
aggregate = mechanics.statistics.aggregateStressStrain(specimens, config);
verifyEqual(testCase, aggregate.centralStress, 2 .* strain, "AbsTol", 1e-12);
verifyEqual(testCase, aggregate.centralStatistic, "median");
verifyEqual(testCase, aggregate.meanStress, (103/3) .* strain, "AbsTol", 1e-12);
end

function testRawUnitNormalization(testCase)
specimen.id = "unit-test";
specimen.raw.force = [0; 1000; 2000];
specimen.raw.displacement = [0; 1000; 2000];
specimen.raw.units.force = "mN";
specimen.raw.units.displacement = "um";
specimen.processingHistory = struct("timestamp",datetime("now"), ...
    "step","synthetic","description","synthetic");
geometry.initialLength = 10;
geometry.initialArea = 2;
config = mechanics.config.tensionConfig();
config.analysis.summaryStrainRange = [0, 0.2];
processed = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, config);
verifyEqual(testCase, processed.processed.force, [0; 1; 2], "AbsTol", 1e-12);
verifyEqual(testCase, processed.processed.displacement, [0; 1; 2], "AbsTol", 1e-12);
verifyEqual(testCase, processed.processed.units.force, "N");
verifyEqual(testCase, processed.processed.units.displacement, "mm");
verifyEqual(testCase, processed.processed.stress, [0; 0.5; 1], "AbsTol", 1e-12);
end

function testGeometryUncertaintyPropagation(testCase)
specimen.id = "uncertainty-test";
specimen.raw.force = [0; 10];
specimen.raw.displacement = [0; 1];
specimen.raw.units.force = "N";
specimen.raw.units.displacement = "mm";
specimen.processingHistory = struct("timestamp",datetime("now"), ...
    "step","synthetic","description","synthetic");
geometry.initialLength = 10;
geometry.initialArea = 2;
config = mechanics.config.tensionConfig();
config.analysis.summaryStrainRange = [0, 0.1];
config.analysis.minimumWindowPoints = 2;
config.uncertainty.geometry.enabled = true;
config.uncertainty.geometry.initialLengthStd = 0.1;
config.uncertainty.geometry.initialAreaStd = 0.02;
processed = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, config);
uncertainty = processed.analysis.geometryUncertainty;
verifyEqual(testCase, uncertainty.strainStandardUncertainty(end), ...
    0.001, "RelTol", 1e-5);
verifyEqual(testCase, uncertainty.stressStandardUncertainty(end), ...
    0.05, "RelTol", 1e-5);
verifyEqual(testCase, uncertainty.strainRelativeStandardUncertainty(end), ...
    0.01, "RelTol", 1e-5);
verifyEqual(testCase, uncertainty.stressRelativeStandardUncertainty(end), ...
    0.01, "RelTol", 1e-5);
end

function testGeometryUncertaintyIsExported(testCase)
specimen.id = "uncertainty-export";
specimen.raw.force = [0; 10; 20];
specimen.raw.displacement = [0; 1; 2];
specimen.raw.units.force = "N";
specimen.raw.units.displacement = "mm";
specimen.processingHistory = struct("timestamp",datetime("now"), ...
    "step","synthetic","description","synthetic");
geometry.initialLength = 10;
geometry.initialArea = 2;
config = mechanics.config.tensionConfig();
config.analysis.summaryStrainRange = [0, 0.2];
config.uncertainty.geometry.enabled = true;
config.uncertainty.geometry.initialLengthStd = 0.1;
config.uncertainty.geometry.initialAreaStd = 0.02;
processed = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, config);
folder = string(tempname);
cleanup = onCleanup(@() localDeleteFolder(folder)); %#ok<NASGU>
files = mechanics.io.exportSpecimenResults(processed, folder);
curveTable = readtable(files.curve);
verifyTrue(testCase, ismember("StrainStandardUncertainty", ...
    string(curveTable.Properties.VariableNames)));
verifyTrue(testCase, ismember("StressStandardUncertainty", ...
    string(curveTable.Properties.VariableNames)));
end

function testTensileStudyExcludesByExtractionIndex(testCase)
filename = localCreateWorkbook();
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
config = mechanics.config.tensileStudyConfig();
config.extraction.defaultInitialLength = 10;
config.specimens.excludeIndices = 1;
config.specimens.exclusionReason = "different preload";
config.specimens.preloadForceOverrides = [0.5; 0.1; 0.1];
config.datasetAnalysis.processingConfig.preprocessing.zeroReference.method = ...
    "preload-threshold";
config.datasetAnalysis.processingConfig.preprocessing.zeroReference.preloadForce = 0.1;
config.datasetAnalysis.processingConfig.preprocessing.zeroReference.sustainedPoints = 2;
config.datasetAnalysis.quality.minimumObservations = 5;
config.population.config.bootstrap.enabled = false;
study = mechanics.workflow.runTensileStudy(filename, config);
verifyEqual(testCase, study.exclusion.indices, 1);
verifyEqual(testCase, study.exclusion.specimenIds, "sample-01");
verifyEqual(testCase, numel(study.dataset.specimens), 2);
verifyEqual(testCase, study.population.specimenCount, 2);
verifyEqual(testCase, string({study.analysis.records.specimenId})', ...
    ["sample-02"; "sample-03"]);
end

function specimen = localProcessedSpecimen(id, strain, stress)
specimen.id = string(id);
specimen.processed.strain = strain;
specimen.processed.stress = stress;
end

function filename = localCreateWorkbook()
filename = string(tempname) + ".xlsx";
results = {
    "", "Identificación de probeta", "h", "b";
    "", "", "mm", "mm";
    "Probeta 1", "sample-01", 2, 6;
    "Probeta 2", "sample-02", 2, 6;
    "Probeta 3", "sample-03", 2, 6
};
writecell(results, filename, "Sheet", "Resultados", "Range", "A1");
for index = 1:3
    preload = 0.1;
    if index == 1
        preload = 0.5;
    end
    displacement = linspace(0, 3, 31)';
    force = preload + 2 .* displacement;
    cells = cell(34, 2);
    cells(1,:) = {"Specimen", "Specimen"};
    cells(2,:) = {"Deformación", "Fuerza estándar"};
    cells(3,:) = {"mm", "N"};
    cells(4:end,1) = num2cell(displacement);
    cells(4:end,2) = num2cell(force);
    writecell(cells, filename, "Sheet", "Probeta " + index, "Range", "A1");
end
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
