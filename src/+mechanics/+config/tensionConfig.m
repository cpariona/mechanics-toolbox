function config = tensionConfig()
%TENSIONCONFIG Default configuration for uniaxial tension analysis.
config.testType = "tension";
config.preprocessing.removeNonfinite = true;
config.preprocessing.zeroForce = true;
config.preprocessing.zeroDisplacement = true;
config.preprocessing.branchMode = "full";
config.preprocessing.startIndex = 1;
config.preprocessing.endIndex = Inf;
config.preprocessing.smoothing.enabled = false;
config.preprocessing.smoothing.method = "sgolay";
config.preprocessing.smoothing.frameLength = 21;
config.preprocessing.smoothing.polynomialOrder = 3;
config.mechanics.stressMeasure = "engineering";
config.mechanics.strainMeasure = "engineering";
config.analysis.modulusStartIndex = 1;
config.analysis.modulusWindowLength = 100;
config.analysis.smoothModulusForPlot = false;
config.analysis.modulusPlotFrameLength = 51;
end
