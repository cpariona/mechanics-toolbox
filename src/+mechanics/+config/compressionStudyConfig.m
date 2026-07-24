function config = compressionStudyConfig()
%COMPRESSIONSTUDYCONFIG Default single-specimen compression-study configuration.
config.import = mechanics.config.excelImportConfig();
config.geometry.initialLength = NaN;
config.geometry.initialArea = NaN;
config.processing = mechanics.config.compressionConfig();

config.cycle.enabled = true;
config.cycle.selection = "last-complete-cycle";
config.cycle.branch = "loading";
config.cycle.loadingDirection = "increasing";
config.cycle.minimumCycleAmplitude = 0;
config.cycle.minimumObservations = 5;
config.cycle.smoothingFrameLength = 5;

config.signConvention = "positive-compression";

config.fitting.enabled = false;
config.fitting.modelNames = ["neo-hookean", "mooney-rivlin", "yeoh"];
config.fitting.context.inputMeasure = "engineering-strain";
config.fitting.context.outputStressMeasure = "nominal";
config.fitting.fitConfig = mechanics.config.fittingConfig();
config.fitting.selectionConfig = mechanics.config.modelSelectionConfig();
config.fitting.measurementMonteCarlo = ...
    mechanics.config.measurementMonteCarloFitConfig();
config.fitting.geometryMonteCarlo = config.fitting.measurementMonteCarlo;

config.export.enabled = false;
config.export.outputFolder = "results/compression-study";
config.export.saveStudyMat = true;
config.export.saveProcessedTable = true;
config.export.saveCycleMetrics = true;
config.export.report = mechanics.config.compressionStudyReportConfig();
end
