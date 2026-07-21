%RUN_BATCH_PROCESSING Process a specimen manifest.
startup;

manifestFile = "path/to/specimen_manifest.xlsx";

config = mechanics.config.batchProcessingConfig();
config.continueOnError = true;
config.exportResults = true;
config.outputFolder = "results/batch-01";

config.fitting.enabled = true;
config.fitting.modelNames = [ ...
    "neo-hookean", "mooney-rivlin", "yeoh"];

batch = mechanics.workflow.processBatchManifest( ...
    manifestFile, config);

disp(batch.summary);

outputFiles = mechanics.io.exportBatchSummary( ...
    batch, config.outputFolder);

disp(outputFiles);
