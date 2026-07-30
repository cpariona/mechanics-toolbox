function audit = auditJointMaterialCharacterization(normalized, config, auditConfig)
%AUDITJOINTMATERIALCHARACTERIZATION Audit joint-fit robustness one factor at a time.
arguments
    normalized (1,1) struct
    config (1,1) struct = mechanics.config.jointMaterialCharacterizationConfig()
    auditConfig (1,1) struct = mechanics.config.jointCharacterizationAuditConfig()
end

localValidateAuditConfig(auditConfig, normalized.modeNames);
scenarios = localScenarios(auditConfig, normalized.modeNames);
scenarioCount = numel(scenarios);
results = repmat(struct("name", "", "perturbation", "", ...
    "result", struct()), scenarioCount, 1);
scenarioName = strings(scenarioCount, 1);
perturbation = strings(scenarioCount, 1);
selectedModel = strings(scenarioCount, 1);
objective = nan(scenarioCount, 1);
sameModelAsBaseline = false(scenarioCount, 1);
parameterRelativeChange = nan(scenarioCount, 1);
specimenCount = zeros(scenarioCount, 1);
observationCount = zeros(scenarioCount, 1);

for scenarioIndex = 1:scenarioCount
    [scenarioData, scenarioConfig] = localApplyScenario( ...
        normalized, config, scenarios(scenarioIndex), auditConfig);
    scenarioResult = mechanics.workflow.selectJointModel( ...
        scenarioData, scenarioConfig);
    results(scenarioIndex).name = scenarios(scenarioIndex).name;
    results(scenarioIndex).perturbation = scenarios(scenarioIndex).perturbation;
    results(scenarioIndex).result = scenarioResult;
    scenarioName(scenarioIndex) = scenarios(scenarioIndex).name;
    perturbation(scenarioIndex) = scenarios(scenarioIndex).perturbation;
    selectedModel(scenarioIndex) = scenarioResult.selectedModelName;
    objective(scenarioIndex) = scenarioResult.selectedFit.objective;
    specimenCount(scenarioIndex) = scenarioData.specimenCount;
    observationCount(scenarioIndex) = scenarioData.observationCount;
end

baselineModel = selectedModel(1);
baselineParameters = results(1).result.selectedFit.parameters(:);
for scenarioIndex = 1:scenarioCount
    sameModelAsBaseline(scenarioIndex) = selectedModel(scenarioIndex) == baselineModel;
    if sameModelAsBaseline(scenarioIndex)
        parameters = results(scenarioIndex).result.selectedFit.parameters(:);
        denominator = max(norm(baselineParameters), sqrt(eps));
        parameterRelativeChange(scenarioIndex) = ...
            norm(parameters - baselineParameters) / denominator;
    end
end

scenarioSummary = table(scenarioName, perturbation, selectedModel, objective, ...
    sameModelAsBaseline, parameterRelativeChange, specimenCount, ...
    observationCount, 'VariableNames', {'Scenario','Perturbation', ...
    'SelectedModel','Objective','SameModelAsBaseline', ...
    'ParameterRelativeChange','SpecimenCount','ObservationCount'});

audit.baseline = results(1).result;
audit.scenarios = results;
audit.scenarioSummary = scenarioSummary;
audit.config = config;
audit.auditConfig = auditConfig;
audit.createdAt = datetime("now");
end

function scenarios = localScenarios(auditConfig, modeNames)
scenarios = struct("name", "baseline", "perturbation", "none", ...
    "kind", "baseline", "value", []);
for index = 2:size(auditConfig.modeWeightSets, 1)
    scenarios(end+1) = struct("name", "mode-weights-" + string(index-1), ...
        "perturbation", "mode weights", "kind", "weights", ...
        "value", auditConfig.modeWeightSets(index, :)); %#ok<AGROW>
end
for index = 2:numel(auditConfig.samplingFractions)
    scenarios(end+1) = struct("name", "sampling-" + ...
        string(auditConfig.samplingFractions(index)), ...
        "perturbation", "sampling density", "kind", "sampling", ...
        "value", auditConfig.samplingFractions(index)); %#ok<AGROW>
end
for index = 2:numel(auditConfig.deformationFractions)
    scenarios(end+1) = struct("name", "deformation-" + ...
        string(auditConfig.deformationFractions(index)), ...
        "perturbation", "deformation range", "kind", "deformation", ...
        "value", auditConfig.deformationFractions(index)); %#ok<AGROW>
end
for index = 2:numel(auditConfig.specimensPerMode)
    scenarios(end+1) = struct("name", "specimens-per-mode-" + ...
        string(auditConfig.specimensPerMode(index)), ...
        "perturbation", "specimen count", "kind", "specimens", ...
        "value", auditConfig.specimensPerMode(index)); %#ok<AGROW>
end
if numel(modeNames) ~= size(auditConfig.modeWeightSets, 2)
    error("mechanics:workflow:InvalidJointAuditModeWeights", ...
        "Each audit mode-weight set must contain one weight per normalized mode.");
end
end

function [output, outputConfig] = localApplyScenario(input, config, scenario, auditConfig)
output = input;
outputConfig = config;
switch scenario.kind
    case "baseline"
    case "weights"
        outputConfig.modeNames = input.modeNames;
        outputConfig.modeWeights = scenario.value(:);
    case "sampling"
        output.specimens = localResampleSpecimens(input.specimens, ...
            scenario.value, auditConfig.minimumObservationsPerSpecimen, false);
    case "deformation"
        output.specimens = localResampleSpecimens(input.specimens, ...
            scenario.value, auditConfig.minimumObservationsPerSpecimen, true);
    case "specimens"
        output.specimens = localLimitSpecimens(input.specimens, ...
            input.modeNames, scenario.value);
    otherwise
        error("mechanics:workflow:UnknownJointAuditScenario", ...
            "Unknown joint audit scenario: %s", scenario.kind);
end
output.specimenCount = numel(output.specimens);
output.observationCount = sum([output.specimens.ObservationCount]);
end

function specimens = localResampleSpecimens(specimens, fraction, minimumCount, byRange)
for specimenIndex = 1:numel(specimens)
    count = specimens(specimenIndex).ObservationCount;
    if byRange
        deformation = specimens(specimenIndex).Deformation(:);
        limit = fraction * max(abs(deformation));
        indices = find(abs(deformation) <= limit + eps(limit));
    else
        retainedCount = max(minimumCount, round(fraction * count));
        indices = unique(round(linspace(1, count, retainedCount)))';
    end
    if numel(indices) < minimumCount
        error("mechanics:workflow:InsufficientJointAuditObservations", ...
            "An audit scenario retained fewer than %d observations.", minimumCount);
    end
    specimens(specimenIndex).Deformation = ...
        specimens(specimenIndex).Deformation(indices);
    specimens(specimenIndex).MeasuredStress = ...
        specimens(specimenIndex).MeasuredStress(indices);
    specimens(specimenIndex).ObservationCount = numel(indices);
end
end

function retained = localLimitSpecimens(specimens, modeNames, countPerMode)
retained = specimens([]);
specimenModes = string({specimens.Mode})';
for modeIndex = 1:numel(modeNames)
    indices = find(specimenModes == modeNames(modeIndex));
    count = min(numel(indices), countPerMode);
    retained = [retained; specimens(indices(1:count))]; %#ok<AGROW>
end
end

function localValidateAuditConfig(config, modeNames)
required = ["modeWeightSets","samplingFractions", ...
    "deformationFractions","specimensPerMode", ...
    "minimumObservationsPerSpecimen"];
if ~all(isfield(config, required))
    error("mechanics:workflow:InvalidJointAuditConfig", ...
        "Joint audit config is missing required fields.");
end
if size(config.modeWeightSets, 2) ~= numel(modeNames) || ...
        any(~isfinite(config.modeWeightSets), "all") || ...
        any(config.modeWeightSets <= 0, "all")
    error("mechanics:workflow:InvalidJointAuditModeWeights", ...
        "Audit mode weights must be finite and positive.");
end
if any(~isfinite(config.samplingFractions)) || ...
        any(config.samplingFractions <= 0 | config.samplingFractions > 1) || ...
        config.samplingFractions(1) ~= 1
    error("mechanics:workflow:InvalidJointAuditSampling", ...
        "Sampling fractions must start at one and lie in (0, 1].");
end
if any(~isfinite(config.deformationFractions)) || ...
        any(config.deformationFractions <= 0 | config.deformationFractions > 1) || ...
        config.deformationFractions(1) ~= 1
    error("mechanics:workflow:InvalidJointAuditDeformationRange", ...
        "Deformation fractions must start at one and lie in (0, 1].");
end
if config.specimensPerMode(1) ~= Inf || ...
        any(config.specimensPerMode(2:end) < 1) || ...
        any(mod(config.specimensPerMode(2:end), 1) ~= 0)
    error("mechanics:workflow:InvalidJointAuditSpecimenCount", ...
        "Specimen counts must start at Inf and continue with positive integers.");
end
if ~isscalar(config.minimumObservationsPerSpecimen) || ...
        config.minimumObservationsPerSpecimen < 3 || ...
        mod(config.minimumObservationsPerSpecimen, 1) ~= 0
    error("mechanics:workflow:InvalidJointAuditMinimumObservations", ...
        "minimumObservationsPerSpecimen must be an integer of at least three.");
end
end
