function summary = summarizeDatasetAnalysis(records)
%SUMMARIZEDATASETANALYSIS Build a table from dataset-analysis records.
arguments
    records struct
end

recordCount = numel(records);

index = nan(recordCount, 1);
specimenId = strings(recordCount, 1);
sheetName = strings(recordCount, 1);
status = strings(recordCount, 1);

qualityPassed = false(recordCount, 1);
failedQualityChecks = strings(recordCount, 1);
observationCount = nan(recordCount, 1);
nonfiniteFraction = nan(recordCount, 1);
displacementReversalFraction = nan(recordCount, 1);

maximumStrain = nan(recordCount, 1);
maximumStress = nan(recordCount, 1);
medianTangentModulus = nan(recordCount, 1);
bestModel = strings(recordCount, 1);
bestModelRMSE = nan(recordCount, 1);
bestModelRSquared = nan(recordCount, 1);

errorIdentifier = strings(recordCount, 1);
errorMessage = strings(recordCount, 1);

for row = 1:recordCount
    record = records(row);

    index(row) = record.index;
    specimenId(row) = record.specimenId;
    sheetName(row) = record.sheetName;
    status(row) = record.status;
    errorIdentifier(row) = record.errorIdentifier;
    errorMessage(row) = record.errorMessage;

    if ~isempty(fieldnames(record.quality))
        qualityPassed(row) = record.quality.passed;
        failedQualityChecks(row) = ...
            strjoin(record.quality.failedChecks, ", ");
        observationCount(row) = ...
            record.quality.finiteObservationCount;
        nonfiniteFraction(row) = ...
            record.quality.nonfiniteFraction;
        displacementReversalFraction(row) = ...
            record.quality.displacementReversalFraction;
    end

    if record.status ~= "processed"
        continue;
    end

    specimen = record.specimen;
    maximumStrain(row) = max(specimen.processed.strain);
    maximumStress(row) = max(specimen.processed.stress);
    medianTangentModulus(row) = ...
        specimen.analysis.tangentModulus.medianModulus;

    if isfield(specimen, "modelSelection") && ...
            specimen.modelSelection.selection.hasEligibleModel
        bestModel(row) = ...
            specimen.modelSelection.selection.bestModel;

        ranked = specimen.modelSelection.selection.rankedSummary;
        bestRow = ranked(ranked.Model == bestModel(row), :);
        bestModelRMSE(row) = bestRow.FullWindowRMSE(1);
        bestModelRSquared(row) = bestRow.FullWindowRSquared(1);
    end
end

summary = table( ...
    index, specimenId, sheetName, status, ...
    qualityPassed, failedQualityChecks, observationCount, ...
    nonfiniteFraction, displacementReversalFraction, ...
    maximumStrain, maximumStress, medianTangentModulus, ...
    bestModel, bestModelRMSE, bestModelRSquared, ...
    errorIdentifier, errorMessage, ...
    'VariableNames', { ...
        'Index', 'SpecimenId', 'SheetName', 'Status', ...
        'QualityPassed', 'FailedQualityChecks', ...
        'ObservationCount', 'NonfiniteFraction', ...
        'DisplacementReversalFraction', ...
        'MaximumStrain', 'MaximumStress', ...
        'MedianTangentModulus', ...
        'BestModel', 'BestModelRMSE', 'BestModelRSquared', ...
        'ErrorIdentifier', 'ErrorMessage'});
end
