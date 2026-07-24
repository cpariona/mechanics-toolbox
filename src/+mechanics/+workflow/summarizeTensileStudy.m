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

excludedSpecimenCount = 0;
if isfield(study, "exclusion") && isfield(study.exclusion, "count")
    excludedSpecimenCount = study.exclusion.count;
end

peakMetricSpecimenCount = 0;
if isfield(study.analysis, "peakSummary")
    peakMetricSpecimenCount = height(study.analysis.peakSummary);
end

summary = table(sourceFile, createdAt, specimenCount, ...
    excludedSpecimenCount, processedSpecimenCount, ...
    qualityFailedSpecimenCount, failedSpecimenCount, ...
    peakMetricSpecimenCount, populationStatus, ...
    'VariableNames', {'SourceFile','CreatedAt','SpecimenCount', ...
    'ExcludedSpecimenCount','ProcessedSpecimenCount', ...
    'QualityFailedSpecimenCount','FailedSpecimenCount', ...
    'PeakMetricSpecimenCount','PopulationStatus'});
end
