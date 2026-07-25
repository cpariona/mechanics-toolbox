function comparison = compareTensileStudies(studies, groupLabels, config)
%COMPARETENSILESTUDIES Compare completed tensile-study results by group.
arguments
    studies struct
    groupLabels string
    config (1,1) struct = mechanics.config.tensileStudyComparisonConfig()
end

studies = studies(:);
groupLabels = string(groupLabels(:));
localValidateInputs(studies, groupLabels);
compatibility = localCompatibility(studies, config);

[combinedAnalysis, assignments, studySummaries] = ...
    localCombineStudies(studies, groupLabels);
combinedAnalysis = mechanics.workflow.assignSpecimenGroups( ...
    combinedAnalysis, assignments, config.groupComparison.groupVariableName);
groupComparison = mechanics.workflow.analyzeGroupComparison( ...
    combinedAnalysis, groupLabels, config.groupComparison);

comparison.groupLabels = groupLabels;
comparison.studySummaries = studySummaries;
comparison.compatibility = compatibility;
comparison.groupComparison = groupComparison;
comparison.config = config;
comparison.createdAt = datetime("now");
end

function localValidateInputs(studies, groupLabels)
if numel(studies) < 2
    error("mechanics:workflow:InsufficientStudies", ...
        "At least two tensile studies are required.");
end
if numel(groupLabels) ~= numel(studies)
    error("mechanics:workflow:StudyLabelCountMismatch", ...
        "Provide exactly one group label per tensile study.");
end
if any(strlength(strtrim(groupLabels)) == 0) || ...
        numel(unique(groupLabels)) ~= numel(groupLabels)
    error("mechanics:workflow:InvalidStudyGroupLabels", ...
        "Study group labels must be nonempty and unique.");
end
requiredStudyFields = ["analysis", "config", "populationStatus"];
for index = 1:numel(studies)
    if ~all(isfield(studies(index), requiredStudyFields)) || ...
            ~isfield(studies(index).analysis, "records") || ...
            ~isfield(studies(index).analysis, "summary") || ...
            ~istable(studies(index).analysis.summary)
        error("mechanics:workflow:InvalidTensileStudy", ...
            "Input %d is not a completed runTensileStudy result.", index);
    end
end
end

function compatibility = localCompatibility(studies, config)
reference = localStudySignature(studies(1));
compatibility.reference = reference;
compatibility.studies = repmat(reference, numel(studies), 1);
compatibility.measuresMatch = true;
compatibility.unitsMatch = true;
for index = 1:numel(studies)
    signature = localStudySignature(studies(index));
    compatibility.studies(index) = signature;
    measuresMatch = signature.strainMeasure == reference.strainMeasure && ...
        signature.stressMeasure == reference.stressMeasure;
    unitsMatch = signature.strainUnit == reference.strainUnit && ...
        signature.stressUnit == reference.stressUnit;
    compatibility.measuresMatch = compatibility.measuresMatch && measuresMatch;
    compatibility.unitsMatch = compatibility.unitsMatch && unitsMatch;
    if config.requireMatchingMeasures && ~measuresMatch
        error("mechanics:workflow:IncompatibleStudyMeasures", ...
            "Tensile studies must use matching strain and stress measures.");
    end
    if config.requireMatchingUnits && ~unitsMatch
        error("mechanics:workflow:IncompatibleStudyUnits", ...
            "Tensile studies must use matching processed strain and stress units.");
    end
end
end

function signature = localStudySignature(study)
processingConfig = study.config.datasetAnalysis.processingConfig;
signature.strainMeasure = string(processingConfig.mechanics.strainMeasure);
signature.stressMeasure = string(processingConfig.mechanics.stressMeasure);
signature.strainUnit = "";
signature.stressUnit = "";
for index = 1:numel(study.analysis.records)
    record = study.analysis.records(index);
    if record.status ~= "processed" || ...
            ~isfield(record.specimen, "processed") || ...
            ~isfield(record.specimen.processed, "units")
        continue;
    end
    units = record.specimen.processed.units;
    if isfield(units, "strain")
        signature.strainUnit = string(units.strain);
    end
    if isfield(units, "stress")
        signature.stressUnit = string(units.stress);
    end
    break;
end
end

function [analysis, assignments, summaries] = localCombineStudies(studies, groupLabels)
records = struct([]);
summaryTables = cell(numel(studies), 1);
summaries = table('Size', [numel(studies), 5], ...
    'VariableTypes', {'string','double','double','string','double'}, ...
    'VariableNames', {'Group','SpecimenCount','ProcessedCount', ...
    'PopulationStatus','SourceFileCount'});

for studyIndex = 1:numel(studies)
    label = groupLabels(studyIndex);
    studyRecords = studies(studyIndex).analysis.records(:);
    for recordIndex = 1:numel(studyRecords)
        originalId = string(studyRecords(recordIndex).specimenId);
        comparisonId = localComparisonId(studyIndex, originalId);
        studyRecords(recordIndex).originalSpecimenId = originalId;
        studyRecords(recordIndex).sourceStudyIndex = studyIndex;
        studyRecords(recordIndex).sourceStudyLabel = label;
        studyRecords(recordIndex).specimenId = comparisonId;
        if isfield(studyRecords(recordIndex), "specimen") && ...
                isfield(studyRecords(recordIndex).specimen, "id")
            studyRecords(recordIndex).specimen.id = comparisonId;
        end
    end
    records = localAppendRecords(records, studyRecords);

    summary = studies(studyIndex).analysis.summary;
    originalIds = string(summary.SpecimenId);
    comparisonIds = strings(height(summary), 1);
    for rowIndex = 1:height(summary)
        comparisonIds(rowIndex) = localComparisonId(studyIndex, originalIds(rowIndex));
    end
    summary.OriginalSpecimenId = originalIds;
    summary.SourceStudyIndex = repmat(studyIndex, height(summary), 1);
    summary.SourceStudyLabel = repmat(label, height(summary), 1);
    summary.SpecimenId = comparisonIds;
    summaryTables{studyIndex} = summary;

    summaries.Group(studyIndex) = label;
    summaries.SpecimenCount(studyIndex) = numel(studyRecords);
    summaries.ProcessedCount(studyIndex) = nnz(summary.Status == "processed");
    summaries.PopulationStatus(studyIndex) = string(studies(studyIndex).populationStatus);
    if isfield(studies(studyIndex), "sourceFiles")
        summaries.SourceFileCount(studyIndex) = numel(studies(studyIndex).sourceFiles);
    else
        summaries.SourceFileCount(studyIndex) = 0;
    end
end

analysis.records = records;
analysis.summary = vertcat(summaryTables{:});
assignments = table(analysis.summary.SpecimenId, ...
    analysis.summary.SourceStudyLabel, ...
    'VariableNames', {'SpecimenId','Group'});
end

function id = localComparisonId(studyIndex, originalId)
id = "study-" + string(studyIndex) + "::" + originalId;
end

function records = localAppendRecords(records, incoming)
if isempty(records)
    records = incoming;
else
    records = [records; incoming]; %#ok<AGROW>
end
end
