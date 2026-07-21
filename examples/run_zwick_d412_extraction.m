%RUN_ZWICK_D412_EXTRACTION Extract the original Zwick/Roell workbook.
startup;

filename = fullfile( ...
    "data", "raw", ...
    "Tension_ASTM_D412_ECOFLEX0050_test.xlsx");

config = mechanics.config.workbookExtractionConfig();
config.extractor = "auto";

% Replace with the actual gauge length used in the experiment.
config.defaultInitialLength = 25;

dataset = mechanics.extraction.extractWorkbook(filename, config);

disp(mechanics.workflow.summarizeExtractedDataset(dataset));

processedDataset = mechanics.workflow.processExtractedDataset( ...
    dataset, mechanics.config.tensionConfig());

disp(processedDataset.summary);

for index = 1:numel(processedDataset.specimens)
    mechanics.plotting.plotStressStrain( ...
        processedDataset.specimens(index).processed);
end
