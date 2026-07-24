function tests = test_geometry_uncertainty
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testGeometryUncertaintyPropagation(testCase)
specimen = localSpecimen("uncertainty-test", [0; 10], [0; 1]);
geometry.initialLength = 10;
geometry.initialArea = 2;
config = localConfig([0, 0.1]);
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
specimen = localSpecimen("uncertainty-export", [0; 10; 20], [0; 1; 2]);
geometry.initialLength = 10;
geometry.initialArea = 2;
config = localConfig([0, 0.2]);
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

function specimen = localSpecimen(id, force, displacement)
specimen.id = id;
specimen.raw.force = force;
specimen.raw.displacement = displacement;
specimen.raw.units.force = "N";
specimen.raw.units.displacement = "mm";
specimen.processingHistory = struct( ...
    "timestamp", datetime("now"), ...
    "step", "synthetic", ...
    "description", "synthetic");
end

function config = localConfig(summaryRange)
config = mechanics.config.tensionConfig();
config.analysis.summaryStrainRange = summaryRange;
config.analysis.minimumWindowPoints = 2;
config.uncertainty.geometry.enabled = true;
config.uncertainty.geometry.initialLengthStd = 0.1;
config.uncertainty.geometry.initialAreaStd = 0.02;
end

function localDeleteFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
