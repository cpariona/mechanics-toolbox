function summary = summarizeDatasetAnalysis(records)
%SUMMARIZEDATASETANALYSIS Build a table from dataset-analysis records.
arguments
    records struct
end

n = numel(records);
index = nan(n,1); specimenId = strings(n,1); sheetName = strings(n,1);
status = strings(n,1);
peakIndex = nan(n,1); peakForce = nan(n,1); peakDisplacement = nan(n,1);
analysisEndIndex = nan(n,1); postPeakDropFraction = nan(n,1);
qualityPassed = false(n,1); failedQualityChecks = strings(n,1);
observationCount = nan(n,1); nonfiniteFraction = nan(n,1);
displacementReversalFraction = nan(n,1);
maximumStrain = nan(n,1); maximumStress = nan(n,1);
medianTangentModulus = nan(n,1); bestModel = strings(n,1);
bestModelRMSE = nan(n,1); bestModelRSquared = nan(n,1);
errorIdentifier = strings(n,1); errorMessage = strings(n,1);

for row = 1:n
    record = records(row);
    index(row)=record.index; specimenId(row)=record.specimenId;
    sheetName(row)=record.sheetName; status(row)=record.status;
    errorIdentifier(row)=record.errorIdentifier;
    errorMessage(row)=record.errorMessage;

    if ~isempty(fieldnames(record.segmentation))
        peakIndex(row)=record.segmentation.peakIndex;
        peakForce(row)=record.segmentation.peakForce;
        peakDisplacement(row)=record.segmentation.peakDisplacement;
        analysisEndIndex(row)=record.segmentation.analysisEndIndex;
        postPeakDropFraction(row)=record.segmentation.postPeakDropFraction;
    end

    if ~isempty(fieldnames(record.quality))
        qualityPassed(row)=record.quality.passed;
        failedQualityChecks(row)=strjoin(record.quality.failedChecks,", ");
        observationCount(row)=record.quality.finiteObservationCount;
        nonfiniteFraction(row)=record.quality.nonfiniteFraction;
        displacementReversalFraction(row)= ...
            record.quality.displacementReversalFraction;
    end

    if record.status ~= "processed"
        continue;
    end
    specimen = record.specimen;
    maximumStrain(row)=max(specimen.processed.strain);
    maximumStress(row)=max(specimen.processed.stress);
    medianTangentModulus(row)= ...
        specimen.analysis.tangentModulus.medianModulus;

    if isfield(specimen,"modelSelection") && ...
            specimen.modelSelection.selection.hasEligibleModel
        bestModel(row)=specimen.modelSelection.selection.bestModel;
        ranked=specimen.modelSelection.selection.rankedSummary;
        bestRow=ranked(ranked.Model==bestModel(row),:);
        bestModelRMSE(row)=bestRow.FullWindowRMSE(1);
        bestModelRSquared(row)=bestRow.FullWindowRSquared(1);
    end
end

summary = table(index,specimenId,sheetName,status, ...
    peakIndex,peakForce,peakDisplacement, ...
    analysisEndIndex,postPeakDropFraction, ...
    qualityPassed,failedQualityChecks,observationCount, ...
    nonfiniteFraction,displacementReversalFraction, ...
    maximumStrain,maximumStress,medianTangentModulus, ...
    bestModel,bestModelRMSE,bestModelRSquared, ...
    errorIdentifier,errorMessage, ...
    'VariableNames',{'Index','SpecimenId','SheetName','Status', ...
    'PeakIndex','PeakForce','PeakDisplacement', ...
    'AnalysisEndIndex','PostPeakDropFraction', ...
    'QualityPassed','FailedQualityChecks','ObservationCount', ...
    'NonfiniteFraction','DisplacementReversalFraction', ...
    'MaximumStrain','MaximumStress','MedianTangentModulus', ...
    'BestModel','BestModelRMSE','BestModelRSquared', ...
    'ErrorIdentifier','ErrorMessage'});
end