function config = compressionConfig()
%COMPRESSIONCONFIG Default configuration for uniaxial compression analysis.
config = mechanics.config.tensionConfig();
config.testType = "compression";
config.preprocessing.branchMode = "manual";
config.preprocessing.startIndex = 1;
config.preprocessing.endIndex = Inf;
config.preprocessing.zeroReference.loadingDirection = "decreasing";
config.analysis.summaryStrainRange = [-0.05, 0.00];
end
