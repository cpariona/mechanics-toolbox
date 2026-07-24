%RUN_BATCH_PROCESSING Process a specimen manifest.
startup;

manifestFile = fullfile( ...
    "examples", "templates", "specimen_manifest_template.csv");

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