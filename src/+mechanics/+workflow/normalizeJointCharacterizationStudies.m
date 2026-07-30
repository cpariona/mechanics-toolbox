function normalized = normalizeJointCharacterizationStudies(studies, modeNames, config)
%NORMALIZEJOINTCHARACTERIZATIONSTUDIES Build joint observations from studies.
arguments
    studies
    modeNames string
    config (1,1) struct = mechanics.config.jointMaterialCharacterizationConfig()
end

studyList = localStudyList(studies);
modeNames = lower(strtrim(string(modeNames(:))));
if numel(studyList) ~= numel(modeNames)
    error("mechanics:workflow:JointStudyModeCountMismatch", ...
        "Provide exactly one mode name per completed study.");
end
if any(strlength(modeNames) == 0) || numel(unique(modeNames)) ~= numel(modeNames)
    error("mechanics:workflow:InvalidJointModeNames", ...
        "Joint-characterization mode names must be nonempty and unique.");
end

configuredModes = lower(strtrim(string(config.modeNames(:))));
configuredWeights = config.modeWeights(:);
if numel(configuredModes) ~= numel(configuredWeights) || ...
        any(~isfinite(configuredWeights)) || any(configuredWeights <= 0)
    error("mechanics:workflow:InvalidJointModeWeights", ...
        "Configure one finite positive weight per configured mode.");
end
signTolerance = localSignTolerance(config);

specimens = struct('Mode',{},'StudyIndex',{},'OriginalSpecimenId',{}, ...
    'SpecimenId',{},'Deformation',{},'MeasuredStress',{},'Context',{}, ...
    'StrainUnit',{},'StressUnit',{},'ObservationCount',{});
mode = strings(numel(modeNames),1);
studyIndex = (1:numel(modeNames))';
specimenCount = zeros(numel(modeNames),1);
observationCount = zeros(numel(modeNames),1);
modeWeight = zeros(numel(modeNames),1);
strainUnit = strings(numel(modeNames),1);
stressUnit = strings(numel(modeNames),1);
deformationMeasure = strings(numel(modeNames),1);
stressMeasure = strings(numel(modeNames),1);

for index = 1:numel(studyList)
    modeContract = mechanics.workflow.jointCharacterizationModeRegistry(modeNames(index));
    study = studyList{index};
    localValidateStudy(study, modeContract, index);
    weightMatch = configuredModes == modeContract.name;
    if nnz(weightMatch) ~= 1
        error("mechanics:workflow:MissingJointModeWeight", ...
            "No unique configured weight exists for mode %s.", modeContract.name);
    end
    mode(index) = modeContract.name;
    modeWeight(index) = configuredWeights(weightMatch);

    records = study.analysis.records(:);
    for recordIndex = 1:numel(records)
        record = records(recordIndex);
        if string(record.status) ~= "processed" || ...
                ~isfield(record, "specimen") || ...
                ~isfield(record.specimen, "processed")
            continue;
        end
        item = localNormalizeRecord(record, modeContract, index, config, signTolerance);
        specimens(end+1,1) = item; %#ok<AGROW>
        specimenCount(index) = specimenCount(index) + 1;
        observationCount(index) = observationCount(index) + item.ObservationCount;
        if strlength(strainUnit(index)) == 0
            strainUnit(index) = item.StrainUnit;
            stressUnit(index) = item.StressUnit;
            deformationMeasure(index) = item.Context.deformationMeasure;
            stressMeasure(index) = item.Context.stressMeasure;
        else
            localRequireEqualMetadata(item, strainUnit(index), stressUnit(index), ...
                deformationMeasure(index), stressMeasure(index), modeContract.name);
        end
    end
    if specimenCount(index) == 0
        error("mechanics:workflow:NoProcessedJointSpecimens", ...
            "Study %d contains no processed specimens for mode %s.", ...
            index, modeContract.name);
    end
end

if config.requireMatchingStressUnits && numel(unique(stressUnit)) ~= 1
    error("mechanics:workflow:IncompatibleJointStressUnits", ...
        "Joint-characterization studies must use matching stress units.");
end
if config.requireMatchingStrainUnits && numel(unique(strainUnit)) ~= 1
    error("mechanics:workflow:IncompatibleJointStrainUnits", ...
        "Joint-characterization studies must use matching strain units.");
end

modeWeight = modeWeight ./ sum(modeWeight);
modeSummary = table(mode, studyIndex, specimenCount, observationCount, ...
    modeWeight, strainUnit, stressUnit, deformationMeasure, stressMeasure, ...
    'VariableNames', {'Mode','StudyIndex','SpecimenCount','ObservationCount', ...
    'ModeWeight','StrainUnit','StressUnit','DeformationMeasure','StressMeasure'});

normalized.modeNames = mode;
normalized.modeWeights = modeWeight;
normalized.specimens = specimens;
normalized.modeSummary = modeSummary;
normalized.specimenCount = numel(specimens);
normalized.observationCount = sum(observationCount);
normalized.config = config;
normalized.createdAt = datetime("now");
end

function studies = localStudyList(input)
if iscell(input)
    studies = input(:);
elseif isstruct(input)
    studies = arrayfun(@(x) x, input(:), 'UniformOutput', false);
else
    error("mechanics:workflow:InvalidJointStudyInput", ...
        "Joint-characterization studies must be a struct array or cell array.");
end
if isempty(studies)
    error("mechanics:workflow:NoJointStudies", ...
        "Provide at least one completed study.");
end
end

function localValidateStudy(study, mode, studyIndex)
if ~isstruct(study) || ~isfield(study, "analysis") || ...
        ~isfield(study.analysis, "records") || ~isfield(study, "populationStatus")
    error("mechanics:workflow:InvalidJointStudy", ...
        "Input %d is not a completed %s study.", studyIndex, mode.name);
end
if string(study.populationStatus) ~= "completed"
    error("mechanics:workflow:IncompleteJointStudy", ...
        "Input %d must have completed population status.", studyIndex);
end
end

function item = localNormalizeRecord(record, mode, studyIndex, config, signTolerance)
processed = record.specimen.processed;
required = [mode.deformationField, mode.stressField, "units", "mechanicsConfig"];
if ~all(isfield(processed, required))
    error("mechanics:workflow:IncompleteJointProcessedRecord", ...
        "Processed specimen %s is missing required joint fields.", ...
        string(record.specimenId));
end

deformation = processed.(mode.deformationField)(:);
stress = processed.(mode.stressField)(:);
if numel(deformation) ~= numel(stress) || numel(deformation) < 2
    error("mechanics:workflow:InvalidJointObservationSize", ...
        "Processed specimen %s must contain aligned deformation and stress vectors.", ...
        string(record.specimenId));
end
if config.requireFiniteObservations && ...
        (any(~isfinite(deformation)) || any(~isfinite(stress)))
    error("mechanics:workflow:NonfiniteJointObservations", ...
        "Processed specimen %s contains nonfinite observations.", ...
        string(record.specimenId));
end
localValidateSigns(deformation, stress, mode, string(record.specimenId), signTolerance);

units = processed.units;
if ~isfield(units, "strain") || ~isfield(units, "stress")
    error("mechanics:workflow:MissingJointUnits", ...
        "Processed specimen %s is missing strain or stress units.", ...
        string(record.specimenId));
end
context = localContext(processed.mechanicsConfig);
originalId = string(record.specimenId);
item.Mode = mode.name;
item.StudyIndex = studyIndex;
item.OriginalSpecimenId = originalId;
item.SpecimenId = mode.name + "::study-" + studyIndex + "::" + originalId;
item.Deformation = deformation;
item.MeasuredStress = stress;
item.Context = context;
item.StrainUnit = string(units.strain);
item.StressUnit = string(units.stress);
item.ObservationCount = numel(deformation);
end

function context = localContext(mechanicsConfig)
if ~isfield(mechanicsConfig, "strainMeasure") || ...
        ~isfield(mechanicsConfig, "stressMeasure")
    error("mechanics:workflow:MissingJointMechanicsMeasures", ...
        "Processed mechanics metadata must define strain and stress measures.");
end
strainMeasure = lower(string(mechanicsConfig.strainMeasure));
stressMeasure = lower(string(mechanicsConfig.stressMeasure));
switch strainMeasure
    case "engineering"
        context.deformationMeasure = "engineering-strain";
    case "true"
        context.deformationMeasure = "true-strain";
    otherwise
        error("mechanics:workflow:UnsupportedJointStrainMeasure", ...
            "Unsupported joint strain measure: %s.", strainMeasure);
end
switch stressMeasure
    case "engineering"
        context.stressMeasure = "nominal";
    case "true"
        context.stressMeasure = "cauchy";
    otherwise
        error("mechanics:workflow:UnsupportedJointStressMeasure", ...
            "Unsupported joint stress measure: %s.", stressMeasure);
end
end

function tolerance = localSignTolerance(config)
if ~isfield(config, "signTolerance") || ~isstruct(config.signTolerance)
    error("mechanics:workflow:MissingJointSignTolerance", ...
        "Joint characterization config must contain signTolerance settings.");
end
required = ["deformationRelative", "stressRelative", "absolute"];
if ~all(isfield(config.signTolerance, required))
    error("mechanics:workflow:InvalidJointSignTolerance", ...
        "signTolerance must define deformationRelative, stressRelative, and absolute.");
end
tolerance = config.signTolerance;
values = [tolerance.deformationRelative, tolerance.stressRelative, tolerance.absolute];
if any(~isfinite(values)) || any(values < 0)
    error("mechanics:workflow:InvalidJointSignTolerance", ...
        "Joint sign tolerances must be finite and nonnegative.");
end
end

function localValidateSigns(deformation, stress, mode, specimenId, config)
deformationTolerance = max(config.absolute, ...
    config.deformationRelative * max(abs(deformation)));
stressTolerance = max(config.absolute, ...
    config.stressRelative * max(abs(stress)));
if mode.expectedDeformationSign == "nonnegative" && ...
        any(deformation < -deformationTolerance)
    error("mechanics:workflow:InvalidJointModeSign", ...
        "Tension specimen %s contains negative stored deformation beyond tolerance.", ...
        specimenId);
end
if mode.expectedDeformationSign == "nonpositive" && ...
        any(deformation > deformationTolerance)
    error("mechanics:workflow:InvalidJointModeSign", ...
        "Compression specimen %s contains positive stored deformation beyond tolerance.", ...
        specimenId);
end
if mode.expectedStressSign == "nonnegative" && any(stress < -stressTolerance)
    error("mechanics:workflow:InvalidJointModeSign", ...
        "Tension specimen %s contains negative stored stress beyond tolerance.", ...
        specimenId);
end
if mode.expectedStressSign == "nonpositive" && any(stress > stressTolerance)
    error("mechanics:workflow:InvalidJointModeSign", ...
        "Compression specimen %s contains positive stored stress beyond tolerance.", ...
        specimenId);
end
end

function localRequireEqualMetadata(item, strainUnit, stressUnit, deformationMeasure, stressMeasure, modeName)
if item.StrainUnit ~= strainUnit || item.StressUnit ~= stressUnit || ...
        item.Context.deformationMeasure ~= deformationMeasure || ...
        item.Context.stressMeasure ~= stressMeasure
    error("mechanics:workflow:InconsistentJointModeMetadata", ...
        "Processed specimens within mode %s must share units and measures.", modeName);
end
end
