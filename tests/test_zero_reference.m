function tests = test_zero_reference
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
