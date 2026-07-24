%RUN_ECOFLEX_TENSILE_STUDY Complete Ecoflex tensile-study workflow.
startup;

filename = fullfile("data", "raw", ...
    "Tension_ASTM_D412_ECOFLEX0050_test.xlsx");

config = mechanics.config.tensileStudyConfig();
config.extraction.defaultInitialLength = 25;

config.datasetAnalysis.segmentation.enabled = true;
config.datasetAnalysis.segmentation.method = "pre-peak";
config.datasetAnalysis.segmentation.analysisPeakFraction = 1.0;

config.datasetAnalysis.fitting.enabled = true;
config.datasetAnalysis.fitting.modelNames = ...
    ["neo-hookean", "mooney-rivlin", "yeoh"];

config.population.config.minimumSpecimens = 2;

config.export.enabled = true;
config.export.outputFolder = ...
    "results/ecoflex-0050/complete-study";

study = mechanics.workflow.runTensileStudy(filename, config);

disp(mechanics.workflow.summarizeTensileStudy(study));
disp(study.analysis.summary);
disp(study.analysis.peakSummary);

if study.populationStatus == "completed"
    disp(study.population.metrics);
end

disp(study.outputFiles);