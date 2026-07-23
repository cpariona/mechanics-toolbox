function config = tensionConfig()
%TENSIONCONFIG Default configuration for uniaxial tension analysis.
config.testType = "tension";
config.preprocessing.removeNonfinite = true;
config.preprocessing.branchMode = "full";
config.preprocessing.startIndex = 1;
config.preprocessing.endIndex = Inf;

config.preprocessing.zeroReference.method = "first-sample";
config.preprocessing.zeroReference.preloadForce = 0;
config.preprocessing.zeroReference.manualIndex = 1;
config.preprocessing.zeroReference.sustainedPoints = 3;
config.preprocessing.zeroReference.trimBeforeReference = true;

config.preprocessing.smoothing.enabled = false;
config.preprocessing.smoothing.method = "sgolay";
config.preprocessing.smoothing.frameLength = 21;
config.preprocessing.smoothing.polynomialOrder = 3;

config.mechanics.stressMeasure = "engineering";
config.mechanics.strainMeasure = "engineering";
config.mechanics.areaEvolution = "incompressible";
config.mechanics.poissonRatio = 0.5;

config.analysis.modulusMethod = "local-linear";
config.analysis.derivativeWindowStrain = 0.02;
config.analysis.summaryStrainRange = [0.00, 0.05];
config.analysis.minimumWindowPoints = 3;
config.analysis.derivativeSmoothing.enabled = true;
config.analysis.derivativeSmoothing.method = "sgolay";
config.analysis.derivativeSmoothing.windowStrain = 0.02;
config.analysis.derivativeSmoothing.polynomialOrder = 3;
end