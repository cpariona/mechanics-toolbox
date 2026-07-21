%RUN_ECOFLEX_DATASET_ANALYSIS Extract, quality-check, process, and fit Ecoflex data.
startup;

filename = fullfile( ...
    "data", "raw", ...
    "Tension_ASTM_D412_ECOFLEX0050_test.xlsx");

extractionConfig = mechanics.config.workbookExtractionConfig();
extractionConfig.extractor = "auto";

% Replace with the actual gauge length used during the experiment.
extractionConfig.defaultInitialLength = 25;

dataset = mechanics.extraction.extractWorkbook( ...
    filename, extractionConfig);

analysisConfig = mechanics.config.datasetAnalysisConfig();

analysisConfig.quality.minimumObservations = 20;
analysisConfig.quality.maximumDisplacementReversalFraction = 0.05;
analysisConfig.quality.rejectFailedQuality = true;

analysisConfig.fitting.enabled = true;
analysisConfig.fitting.modelNames = [ ...
    "neo-hookean", "mooney-rivlin", "yeoh"];
analysisConfig.fitting.selectionConfig.windowFractions = ...
    [0.40, 0.60, 0.80, 1.00];
analysisConfig.fitting.selectionConfig.minimumObservations = 20;

analysis = mechanics.workflow.analyzeExtractedDataset( ...
    dataset, analysisConfig);

disp(analysis.summary);

mechanics.plotting.plotDatasetStressStrain(analysis);

outputFiles = mechanics.io.exportDatasetAnalysis( ...
    analysis, "results/ecoflex-0050");

disp(outputFiles);
