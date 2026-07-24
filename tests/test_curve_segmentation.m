function tests = test_curve_segmentation
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testPrePeakSegmentation(testCase)
raw.force = [0;1;2;3;1;0];
raw.displacement = [0;1;2;3;2.5;2];
config = mechanics.config.curveSegmentationConfig();
config.minimumObservations = 3;
result = mechanics.segmentation.segmentTensileCurve(raw,config);
verifyEqual(testCase,result.peakIndex,4);
verifyEqual(testCase,result.analysisEndIndex,4);
verifyEqual(testCase,result.analysisRaw.force,[0;1;2;3]);
verifyEqual(testCase,result.postPeakDropFraction,1);
end

function testPeakFractionCanTrimBeforePeak(testCase)
raw.force=(0:10)'; raw.displacement=(0:10)';
config=mechanics.config.curveSegmentationConfig();
config.minimumObservations=3;
config.analysisPeakFraction=0.8;
result=mechanics.segmentation.segmentTensileCurve(raw,config);
verifyEqual(testCase,result.peakIndex,11);
verifyEqual(testCase,result.analysisEndIndex,9);
verifyEqual(testCase,result.analysisRaw.force(end),8);
end

function testPostPeakReversalDoesNotFailQuality(testCase)
dataset.specimens=localSpecimen();
config=mechanics.config.datasetAnalysisConfig();
config.segmentation.minimumObservations=3;
config.quality.minimumObservations=3;
config.quality.maximumDisplacementReversalFraction=0;
analysis=mechanics.workflow.analyzeExtractedDataset(dataset,config);
verifyEqual(testCase,analysis.summary.Status,"processed");
verifyEqual(testCase,analysis.summary.DisplacementReversalFraction,0);
verifyEqual(testCase,analysis.summary.AnalysisEndIndex,6);
verifyEqual(testCase,numel(analysis.records(1).specimen.raw.force),9);
verifyEqual(testCase,numel(analysis.records(1).specimen.analysisRaw.force),6);
end

function specimen=localSpecimen()
specimen.id="fracture"; specimen.sheetName="fracture";
specimen.testType="tension";
specimen.raw.displacement=[0;1;2;3;4;5;4.5;4;3.5];
specimen.raw.force=[0;1;2;3;4;5;3;1;0];
specimen.geometry.initialLength=10;
specimen.geometry.initialArea=2;
specimen.source.filename="synthetic";
specimen.metadata=struct();
specimen.processingHistory=struct("timestamp",datetime("now"), ...
    "step","synthetic","description","synthetic fracture curve");
end