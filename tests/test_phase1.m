function tests = test_phase1
tests = functiontests(localfunctions);
end
function setupOnce(~)
startup;
end
function testEngineeringMeasures(testCase)
config = mechanics.config.tensionConfig();
raw.force = [0; 10; 20];
raw.displacement = [0; 1; 2];
curve = mechanics.preprocessing.prepareCurve(raw, config.preprocessing);
geometry.initialLength = 10;
geometry.initialArea = 2;
curve = mechanics.analysis.computeUniaxialMeasures(curve, geometry, config.mechanics);
verifyEqual(testCase, curve.strain, [0; .1; .2], "AbsTol", 1e-12);
verifyEqual(testCase, curve.stress, [0; 5; 10], "AbsTol", 1e-12);
end
function testRawDataArePreserved(testCase)
config = mechanics.config.tensionConfig();
raw.force = [5; 6; 7];
raw.displacement = [2; 3; 4];
curve = mechanics.preprocessing.prepareCurve(raw, config.preprocessing);
verifyEqual(testCase, curve.raw, raw);
verifyEqual(testCase, curve.force, [0; 1; 2]);
verifyEqual(testCase, curve.displacement, [0; 1; 2]);
end
function testTangentModulus(testCase)
config = mechanics.config.tensionConfig();
curve.strain = linspace(0, 1, 101)';
curve.stress = 3 .* curve.strain;
result = mechanics.analysis.computeTangentModulus(curve, config.analysis);
verifyEqual(testCase, result.medianModulus, 3, "AbsTol", 1e-10);
end
function testInvalidGeometry(testCase)
config = mechanics.config.tensionConfig();
raw.force = [0; 1]; raw.displacement = [0; 1];
curve = mechanics.preprocessing.prepareCurve(raw, config.preprocessing);
geometry.initialLength = 1; geometry.initialArea = 0;
verifyError(testCase, @() mechanics.analysis.computeUniaxialMeasures(curve, geometry, config.mechanics), "mechanics:analysis:InvalidGeometry");
end
