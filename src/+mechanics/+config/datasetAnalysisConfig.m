function config = datasetAnalysisConfig()
%DATASETANALYSISCONFIG Default configuration for extracted-dataset analysis.
config.processingConfig = mechanics.config.tensionConfig();
config.continueOnError = true;

config.quality.minimumObservations = 20;
config.quality.requireMonotonicDisplacement = false;
config.quality.maximumDisplacementReversalFraction = 0.05;
config.quality.minimumDisplacementRange = 0;
config.quality.minimumForceRange = 0;
config.quality.maximumNonfiniteFraction = 0;
config.quality.rejectFailedQuality = true;

config.fitting.enabled = false;
config.fitting.modelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
config.fitting.context.inputMeasure = "engineering-strain";
config.fitting.context.outputStressMeasure = "nominal";
config.fitting.fitConfig = mechanics.config.fittingConfig();
config.fitting.selectionConfig = mechanics.config.modelSelectionConfig();

config.export.enabled = false;
config.export.outputFolder = "results/dataset";
end
