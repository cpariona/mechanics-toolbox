%RUN_ECOFLEX_SEGMENTED_ANALYSIS Analyze Ecoflex curves before fracture.
startup;
filename=fullfile("data","raw", ...
    "Tension_ASTM_D412_ECOFLEX0050_test.xlsx");
extractionConfig=mechanics.config.workbookExtractionConfig();
extractionConfig.defaultInitialLength=25;
dataset=mechanics.extraction.extractWorkbook(filename,extractionConfig);

analysisConfig=mechanics.config.datasetAnalysisConfig();
analysisConfig.segmentation.enabled=true;
analysisConfig.segmentation.method="pre-peak";
analysisConfig.segmentation.analysisPeakFraction=1.0;
analysisConfig.segmentation.minimumPostPeakDropFraction=0.20;
analysisConfig.fitting.enabled=true;
analysisConfig.fitting.modelNames=["neo-hookean","mooney-rivlin","yeoh"];

analysis=mechanics.workflow.analyzeExtractedDataset(dataset,analysisConfig);
disp(analysis.summary(:,{'SpecimenId','Status','FractureDetected', ...
    'PeakForce','PeakDisplacement','AnalysisEndIndex', ...
    'DisplacementReversalFraction','BestModel'}));
mechanics.plotting.plotDatasetStressStrain(analysis);
