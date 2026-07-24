function config = batchProcessingConfig()
%BATCHPROCESSINGCONFIG Default configuration for manifest-driven processing.
config.importConfig = mechanics.config.excelImportConfig();
config.processingConfig = mechanics.config.tensionConfig();
config.continueOnError = true;
config.exportResults = false;
config.outputFolder = "results";
config.fitting.enabled = false;
config.fitting.modelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
config.fitting.context.deformationMeasure = "engineering-strain";
config.fitting.context.stressMeasure = "nominal";
config.fitting.fitConfig = mechanics.config.fittingConfig();
config.fitting.selectionConfig = mechanics.config.modelSelectionConfig();
end
