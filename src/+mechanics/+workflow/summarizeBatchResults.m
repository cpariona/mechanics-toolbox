function summary = summarizeBatchResults(records)
%SUMMARIZEBATCHRESULTS Build a compact table from batch-processing records.
arguments
    records struct
end

recordCount = numel(records);
rowIndex = nan(recordCount, 1);
specimenId = strings(recordCount, 1);
filename = strings(recordCount, 1);
testType = strings(recordCount, 1);
status = strings(recordCount, 1);
observationCount = nan(recordCount, 1);
maximumStrain = nan(recordCount, 1);
maximumStress = nan(recordCount, 1);
medianTangentModulus = nan(recordCount, 1);
bestModel = strings(recordCount, 1);
errorIdentifier = strings(recordCount, 1);
errorMessage = strings(recordCount, 1);

for index = 1:recordCount
    record = records(index);
    rowIndex(index) = record.rowIndex;
    specimenId(index) = record.specimenId;
    filename(index) = record.filename;
    testType(index) = record.testType;
    status(index) = record.status;
    errorIdentifier(index) = record.errorIdentifier;
    errorMessage(index) = record.errorMessage;

    if record.status ~= "processed"
        continue;
    end

    specimen = record.specimen;
    observationCount(index) = numel(specimen.processed.strain);
    maximumStrain(index) = max(specimen.processed.strain);
    maximumStress(index) = max(specimen.processed.stress);
    medianTangentModulus(index) = ...
        specimen.analysis.tangentModulus.medianModulus;

    if isfield(specimen, "modelSelection") && ...
            specimen.modelSelection.selection.hasEligibleModel
        bestModel(index) = ...
            specimen.modelSelection.selection.bestModel;
    end
end

summary = table( ...
    rowIndex, specimenId, filename, testType, status, ...
    observationCount, maximumStrain, maximumStress, ...
    medianTangentModulus, bestModel, ...
    errorIdentifier, errorMessage, ...
    'VariableNames', { ...
        'RowIndex', 'SpecimenId', 'File', 'TestType', 'Status', ...
        'ObservationCount', 'MaximumStrain', 'MaximumStress', ...
        'MedianTangentModulus', 'BestModel', ...
        'ErrorIdentifier', 'ErrorMessage'});
end
