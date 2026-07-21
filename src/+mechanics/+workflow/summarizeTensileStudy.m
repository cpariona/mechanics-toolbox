function summary = summarizeTensileStudy(study)
%SUMMARIZETENSILESTUDY Build a one-row study summary.
arguments
    study (1,1) struct
end

p = study.provenance;
sourceFile = p.sourceFile;
createdAt = study.createdAt;
specimenCount = p.specimenCount;
processedSpecimenCount = p.processedSpecimenCount;
qualityFailedSpecimenCount = p.qualityFailedSpecimenCount;
failedSpecimenCount = p.failedSpecimenCount;
populationStatus = study.populationStatus;

fractureDetectedCount = NaN;
completeFractureCount = NaN;
if isfield(study.analysis, "fractureSummary")
    fractureDetectedCount = ...
        nnz(study.analysis.fractureSummary.FractureDetected);
    completeFractureCount = ...
        nnz(study.analysis.fractureSummary.CompleteFracture);
end

summary = table(sourceFile, createdAt, specimenCount, ...
    processedSpecimenCount, qualityFailedSpecimenCount, ...
    failedSpecimenCount, fractureDetectedCount, ...
    completeFractureCount, populationStatus, ...
    'VariableNames', {'SourceFile','CreatedAt','SpecimenCount', ...
    'ProcessedSpecimenCount','QualityFailedSpecimenCount', ...
    'FailedSpecimenCount','FractureDetectedCount', ...
    'CompleteFractureCount','PopulationStatus'});
end
