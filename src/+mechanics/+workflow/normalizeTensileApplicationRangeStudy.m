function normalized = normalizeTensileApplicationRangeStudy(tensileStudy, config)
%NORMALIZETENSILEAPPLICATIONRANGESTUDY Extract range-limited tensile observations.
arguments
    tensileStudy (1,1) struct
    config (1,1) struct = ...
        mechanics.config.tensileApplicationRangeCharacterizationConfig()
end

config = localValidateConfig(config);
localValidateStudy(tensileStudy);
records = tensileStudy.analysis.records(:);

specimens = repmat(localEmptySpecimen(), 0, 1);
excludedSpecimens = repmat(localEmptyExclusion(), 0, 1);
processedRecordCount = 0;

for recordIndex = 1:numel(records)
    record = records(recordIndex);
    if ~isfield(record, "status") || string(record.status) ~= "processed"
        continue
    end
    processedRecordCount = processedRecordCount + 1;
    [item, exclusion] = localNormalizeRecord(record, recordIndex, config);
    if strlength(exclusion.Reason) > 0
        excludedSpecimens(end+1, 1) = exclusion; %#ok<AGROW>
    else
        specimens(end+1, 1) = item; %#ok<AGROW>
    end
end

if processedRecordCount == 0
    error("mechanics:workflow:NoProcessedTensileApplicationRangeSpecimens", ...
        "The completed tensile study contains no processed specimen records.");
end
if numel(specimens) < config.minimumSpecimens
    error("mechanics:workflow:InsufficientTensileApplicationRangeSpecimens", ...
        "The configured range retained %d specimens; at least %d are required.", ...
        numel(specimens), config.minimumSpecimens);
end

localValidateCommonMetadata(specimens, config);

normalized.sourceStudyMetadata = localSourceStudyMetadata( ...
    tensileStudy, numel(records), processedRecordCount);
normalized.deformationMeasure = config.deformationMeasure;
normalized.requestedFitRange = config.fitRange;
normalized.specimens = specimens;
normalized.excludedSpecimens = excludedSpecimens;
normalized.specimenCount = numel(specimens);
normalized.excludedSpecimenCount = numel(excludedSpecimens);
normalized.observationCount = sum([specimens.ObservationCount]);
normalized.specimenSummary = localSpecimenSummary(specimens);
normalized.exclusionSummary = localExclusionSummary(excludedSpecimens);
normalized.config = config;
normalized.createdAt = datetime("now");
end

function config = localValidateConfig(config)
required = ["deformationMeasure", "fitRange", ...
    "minimumObservationsPerSpecimen", "minimumSpecimens", ...
    "requireRangeMaximum", "candidateModelNames", ...
    "requireFiniteObservations", "requireMatchingStressUnits", ...
    "requireMatchingStrainUnits", "signTolerance"];
if ~all(isfield(config, required))
    error("mechanics:workflow:InvalidTensileApplicationRangeConfig", ...
        "The application-range configuration is incomplete.");
end

config.deformationMeasure = lower(strtrim(string(config.deformationMeasure)));
if ~isscalar(config.deformationMeasure) || ...
        ~ismember(config.deformationMeasure, ["engineering-strain", "true-strain"])
    error("mechanics:workflow:UnsupportedTensileApplicationRangeDeformationMeasure", ...
        "Supported deformation measures are engineering-strain and true-strain.");
end

config.fitRange = reshape(double(config.fitRange), 1, []);
if numel(config.fitRange) ~= 2 || any(~isfinite(config.fitRange)) || ...
        config.fitRange(1) >= config.fitRange(2)
    error("mechanics:workflow:InvalidTensileApplicationFitRange", ...
        "fitRange must contain two finite increasing limits.");
end

integerFields = ["minimumObservationsPerSpecimen", "minimumSpecimens"];
for index = 1:numel(integerFields)
    fieldName = integerFields(index);
    value = double(config.(fieldName));
    if ~isscalar(value) || ~isfinite(value) || value < 1 || value ~= round(value)
        error("mechanics:workflow:InvalidTensileApplicationRangeConfig", ...
            "%s must be a positive integer.", fieldName);
    end
    config.(fieldName) = value;
end

logicalFields = ["requireRangeMaximum", "requireFiniteObservations", ...
    "requireMatchingStressUnits", "requireMatchingStrainUnits"];
for index = 1:numel(logicalFields)
    fieldName = logicalFields(index);
    value = config.(fieldName);
    if ~isscalar(value)
        error("mechanics:workflow:InvalidTensileApplicationRangeConfig", ...
            "%s must be scalar logical-like.", fieldName);
    end
    config.(fieldName) = logical(value);
end

modelNames = lower(strtrim(string(config.candidateModelNames(:))));
if isempty(modelNames) || any(strlength(modelNames) == 0) || ...
        numel(unique(modelNames)) ~= numel(modelNames)
    error("mechanics:workflow:InvalidTensileApplicationRangeCandidateModels", ...
        "Candidate model names must be nonempty and unique.");
end
for index = 1:numel(modelNames)
    mechanics.models.modelRegistry(modelNames(index));
end
config.candidateModelNames = modelNames;
config.signTolerance = localValidateSignTolerance(config.signTolerance);
end

function tolerance = localValidateSignTolerance(tolerance)
required = ["deformationRelative", "stressRelative", "absolute"];
if ~isstruct(tolerance) || ~all(isfield(tolerance, required))
    error("mechanics:workflow:InvalidTensileApplicationRangeSignTolerance", ...
        "signTolerance must define deformationRelative, stressRelative, and absolute.");
end
values = [tolerance.deformationRelative, ...
    tolerance.stressRelative, tolerance.absolute];
if any(~isfinite(values)) || any(values < 0)
    error("mechanics:workflow:InvalidTensileApplicationRangeSignTolerance", ...
        "Application-range sign tolerances must be finite and nonnegative.");
end
end

function localValidateStudy(study)
if ~isfield(study, "analysis") || ~isstruct(study.analysis) || ...
        ~isfield(study.analysis, "records") || isempty(study.analysis.records)
    error("mechanics:workflow:InvalidTensileApplicationRangeStudy", ...
        "Provide a completed tensile study containing analysis.records.");
end
end

function [item, exclusion] = localNormalizeRecord(record, recordIndex, config)
item = localEmptySpecimen();
exclusion = localEmptyExclusion();
exclusion.SourceRecordIndex = recordIndex;
exclusion.SourceSpecimenId = localSpecimenId(record, recordIndex);

if ~isfield(record, "specimen") || ~isstruct(record.specimen) || ...
        ~isfield(record.specimen, "processed")
    error("mechanics:workflow:IncompleteTensileApplicationRangeRecord", ...
        "Processed record %d does not contain specimen.processed.", recordIndex);
end
processed = record.specimen.processed;
required = ["strain", "stress", "units", "mechanicsConfig"];
if ~all(isfield(processed, required))
    error("mechanics:workflow:IncompleteTensileApplicationRangeRecord", ...
        "Processed specimen %s is missing required mechanical fields.", ...
        exclusion.SourceSpecimenId);
end

deformation = processed.strain(:);
stress = processed.stress(:);
if numel(deformation) ~= numel(stress) || numel(deformation) < 2
    error("mechanics:workflow:InvalidTensileApplicationRangeObservationSize", ...
        "Processed specimen %s must contain aligned deformation and stress vectors.", ...
        exclusion.SourceSpecimenId);
end
if config.requireFiniteObservations && ...
        (any(~isfinite(deformation)) || any(~isfinite(stress)))
    error("mechanics:workflow:NonfiniteTensileApplicationRangeObservations", ...
        "Processed specimen %s contains nonfinite observations.", ...
        exclusion.SourceSpecimenId);
end

context = localContext(processed.mechanicsConfig);
if context.deformationMeasure ~= config.deformationMeasure
    error("mechanics:workflow:IncompatibleTensileApplicationRangeMeasure", ...
        "Processed specimen %s uses %s, not the configured %s.", ...
        exclusion.SourceSpecimenId, context.deformationMeasure, ...
        config.deformationMeasure);
end
localValidateTensionSigns(deformation, stress, exclusion.SourceSpecimenId, ...
    config.signTolerance);
[strainUnit, stressUnit] = localUnits(processed.units, exclusion.SourceSpecimenId);

included = deformation >= config.fitRange(1) & ...
    deformation <= config.fitRange(2);
availableRange = [min(deformation), max(deformation)];
if config.requireRangeMaximum && availableRange(2) < config.fitRange(2)
    exclusion.Reason = "requested-maximum-unavailable";
    exclusion.AvailableRange = availableRange;
    exclusion.IncludedObservationCount = nnz(included);
    return
end
if nnz(included) < config.minimumObservationsPerSpecimen
    exclusion.Reason = "insufficient-range-observations";
    exclusion.AvailableRange = availableRange;
    exclusion.IncludedObservationCount = nnz(included);
    return
end

item.SourceRecordIndex = recordIndex;
item.SourceSpecimenId = exclusion.SourceSpecimenId;
item.SourceSheetName = localSheetName(record);
item.FullDeformation = deformation;
item.FullMeasuredStress = stress;
item.IncludedIndices = find(included);
item.ExcludedIndices = find(~included);
item.Deformation = deformation(included);
item.MeasuredStress = stress(included);
item.AvailableRange = availableRange;
item.RequestedFitRange = config.fitRange;
item.FittedRange = [min(item.Deformation), max(item.Deformation)];
item.Context = context;
item.StrainUnit = strainUnit;
item.StressUnit = stressUnit;
item.ObservationCount = numel(item.Deformation);
item.ExcludedObservationCount = nnz(~included);
end

function context = localContext(mechanicsConfig)
if ~isfield(mechanicsConfig, "strainMeasure") || ...
        ~isfield(mechanicsConfig, "stressMeasure")
    error("mechanics:workflow:MissingTensileApplicationRangeMechanicsMeasures", ...
        "Processed mechanics metadata must define strain and stress measures.");
end
switch lower(string(mechanicsConfig.strainMeasure))
    case "engineering"
        context.deformationMeasure = "engineering-strain";
    case "true"
        context.deformationMeasure = "true-strain";
    otherwise
        error("mechanics:workflow:UnsupportedTensileApplicationRangeDeformationMeasure", ...
            "Unsupported stored strain measure: %s.", ...
            string(mechanicsConfig.strainMeasure));
end
switch lower(string(mechanicsConfig.stressMeasure))
    case "engineering"
        context.stressMeasure = "nominal";
    case "true"
        context.stressMeasure = "cauchy";
    otherwise
        error("mechanics:workflow:UnsupportedTensileApplicationRangeStressMeasure", ...
            "Unsupported stored stress measure: %s.", ...
            string(mechanicsConfig.stressMeasure));
end
end

function localValidateTensionSigns(deformation, stress, specimenId, tolerance)
deformationTolerance = max(tolerance.absolute, ...
    tolerance.deformationRelative * max(abs(deformation)));
stressTolerance = max(tolerance.absolute, ...
    tolerance.stressRelative * max(abs(stress)));
if any(deformation < -deformationTolerance) || any(stress < -stressTolerance)
    error("mechanics:workflow:InvalidTensileApplicationRangeSign", ...
        "Tensile specimen %s contains material negative deformation or stress.", ...
        specimenId);
end
end

function [strainUnit, stressUnit] = localUnits(units, specimenId)
if ~isstruct(units) || ~isfield(units, "strain") || ~isfield(units, "stress")
    error("mechanics:workflow:MissingTensileApplicationRangeUnits", ...
        "Processed specimen %s is missing strain or stress units.", specimenId);
end
strainUnit = string(units.strain);
stressUnit = string(units.stress);
end

function localValidateCommonMetadata(specimens, config)
strainUnits = string({specimens.StrainUnit})';
stressUnits = string({specimens.StressUnit})';
deformationMeasures = strings(numel(specimens), 1);
stressMeasures = strings(numel(specimens), 1);
for index = 1:numel(specimens)
    deformationMeasures(index) = specimens(index).Context.deformationMeasure;
    stressMeasures(index) = specimens(index).Context.stressMeasure;
end
if config.requireMatchingStrainUnits && numel(unique(strainUnits)) ~= 1
    error("mechanics:workflow:InconsistentTensileApplicationRangeMetadata", ...
        "Retained tensile specimens must use matching strain units.");
end
if config.requireMatchingStressUnits && numel(unique(stressUnits)) ~= 1
    error("mechanics:workflow:InconsistentTensileApplicationRangeMetadata", ...
        "Retained tensile specimens must use matching stress units.");
end
if numel(unique(deformationMeasures)) ~= 1 || numel(unique(stressMeasures)) ~= 1
    error("mechanics:workflow:InconsistentTensileApplicationRangeMetadata", ...
        "Retained tensile specimens must share one constitutive context.");
end
end

function metadata = localSourceStudyMetadata(study, recordCount, processedCount)
metadata.recordCount = recordCount;
metadata.processedRecordCount = processedCount;
if isfield(study, "sourceFile")
    metadata.sourceFile = string(study.sourceFile);
else
    metadata.sourceFile = "";
end
if isfield(study, "sourceFiles")
    metadata.sourceFiles = string(study.sourceFiles(:));
else
    metadata.sourceFiles = strings(0, 1);
end
if isfield(study, "createdAt")
    metadata.createdAt = study.createdAt;
else
    metadata.createdAt = NaT;
end
if isfield(study, "provenance")
    metadata.provenance = study.provenance;
else
    metadata.provenance = struct();
end
end

function output = localSpecimenSummary(specimens)
sourceRecordIndex = reshape([specimens.SourceRecordIndex], [], 1);
sourceSpecimenId = reshape(string({specimens.SourceSpecimenId}), [], 1);
availableMinimum = reshape(arrayfun( ...
    @(item) item.AvailableRange(1), specimens), [], 1);
availableMaximum = reshape(arrayfun( ...
    @(item) item.AvailableRange(2), specimens), [], 1);
fittedMinimum = reshape(arrayfun( ...
    @(item) item.FittedRange(1), specimens), [], 1);
fittedMaximum = reshape(arrayfun( ...
    @(item) item.FittedRange(2), specimens), [], 1);
includedObservationCount = reshape([specimens.ObservationCount], [], 1);
excludedObservationCount = reshape( ...
    [specimens.ExcludedObservationCount], [], 1);
output = table(sourceRecordIndex, sourceSpecimenId, availableMinimum, ...
    availableMaximum, fittedMinimum, fittedMaximum, ...
    includedObservationCount, excludedObservationCount, ...
    'VariableNames', {'SourceRecordIndex','SourceSpecimenId', ...
    'AvailableMinimum','AvailableMaximum','FittedMinimum','FittedMaximum', ...
    'IncludedObservationCount','ExcludedObservationCount'});
end

function output = localExclusionSummary(exclusions)
if isempty(exclusions)
    output = table('Size', [0, 5], ...
        'VariableTypes', {'double','string','string','double','double'}, ...
        'VariableNames', {'SourceRecordIndex','SourceSpecimenId','Reason', ...
        'AvailableMaximum','IncludedObservationCount'});
    return
end
sourceRecordIndex = reshape([exclusions.SourceRecordIndex], [], 1);
sourceSpecimenId = reshape(string({exclusions.SourceSpecimenId}), [], 1);
reason = reshape(string({exclusions.Reason}), [], 1);
availableMaximum = reshape(arrayfun( ...
    @(item) item.AvailableRange(2), exclusions), [], 1);
includedObservationCount = reshape( ...
    [exclusions.IncludedObservationCount], [], 1);
output = table(sourceRecordIndex, sourceSpecimenId, reason, ...
    availableMaximum, includedObservationCount, ...
    'VariableNames', {'SourceRecordIndex','SourceSpecimenId','Reason', ...
    'AvailableMaximum','IncludedObservationCount'});
end

function specimenId = localSpecimenId(record, recordIndex)
if isfield(record, "specimenId") && strlength(string(record.specimenId)) > 0
    specimenId = string(record.specimenId);
elseif isfield(record, "specimen") && isfield(record.specimen, "id")
    specimenId = string(record.specimen.id);
else
    specimenId = "record-" + recordIndex;
end
end

function sheetName = localSheetName(record)
if isfield(record, "sheetName")
    sheetName = string(record.sheetName);
elseif isfield(record, "specimen") && isfield(record.specimen, "sheetName")
    sheetName = string(record.specimen.sheetName);
else
    sheetName = "";
end
end

function item = localEmptySpecimen()
item.SourceRecordIndex = NaN;
item.SourceSpecimenId = "";
item.SourceSheetName = "";
item.FullDeformation = [];
item.FullMeasuredStress = [];
item.IncludedIndices = [];
item.ExcludedIndices = [];
item.Deformation = [];
item.MeasuredStress = [];
item.AvailableRange = [NaN, NaN];
item.RequestedFitRange = [NaN, NaN];
item.FittedRange = [NaN, NaN];
item.Context = struct();
item.StrainUnit = "";
item.StressUnit = "";
item.ObservationCount = 0;
item.ExcludedObservationCount = 0;
end

function item = localEmptyExclusion()
item.SourceRecordIndex = NaN;
item.SourceSpecimenId = "";
item.Reason = "";
item.AvailableRange = [NaN, NaN];
item.IncludedObservationCount = 0;
end