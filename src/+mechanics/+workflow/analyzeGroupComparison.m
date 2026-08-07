function result = analyzeGroupComparison(analysis, groupNames, config)
%ANALYZEGROUPCOMPARISON Build group populations and pairwise comparisons.
arguments
    analysis (1,1) struct
    groupNames string = strings(0,1)
    config (1,1) struct = mechanics.config.groupComparisonConfig()
end

if ~isfield(analysis, "summary") || ...
        ~ismember(config.groupVariableName, ...
        string(analysis.summary.Properties.VariableNames))
    error("mechanics:workflow:MissingGroupAssignments", ...
        "Assign specimen groups before comparison.");
end

groupVariable = string(analysis.summary.(config.groupVariableName));
processed = analysis.summary.Status == "processed";
if isempty(groupNames)
    groupNames = unique(groupVariable(processed & groupVariable ~= ""), "stable");
else
    groupNames = string(groupNames(:));
end
if numel(groupNames) < 2
    error("mechanics:workflow:InsufficientGroups", ...
        "At least two groups are required.");
end

groups = repmat(struct( ...
    'name', "", ...
    'population', struct(), ...
    'specimenCount', 0, ...
    'summary', table()), numel(groupNames), 1);

for groupIndex = 1:numel(groupNames)
    name = groupNames(groupIndex);
    mask = false(numel(analysis.records), 1);
    for recordIndex = 1:numel(analysis.records)
        mask(recordIndex) = isfield(analysis.records(recordIndex), "group") && ...
            analysis.records(recordIndex).status == "processed" && ...
            string(analysis.records(recordIndex).group) == name;
    end

    records = analysis.records(mask);
    if numel(records) < config.minimumSpecimensPerGroup
        error("mechanics:workflow:InsufficientGroupSpecimens", ...
            "Group %s requires at least %d processed specimens.", ...
            name, config.minimumSpecimensPerGroup);
    end

    groupAnalysis.records = records;
    groupAnalysis.summary = analysis.summary(processed & groupVariable == name, :);
    populationConfig = config.populationConfig;
    populationConfig.minimumSpecimens = config.minimumSpecimensPerGroup;
    population = mechanics.workflow.analyzeSpecimenPopulation( ...
        groupAnalysis, populationConfig);

    groups(groupIndex).name = name;
    groups(groupIndex).population = population;
    groups(groupIndex).specimenCount = population.specimenCount;
    groups(groupIndex).summary = groupAnalysis.summary;
end

result.groups = groups;
result.groupNames = groupNames;
result.mechanics = localMechanicsMetadata(analysis.records);
result.testType = localTestType(analysis.records);
result.modelInitialShearSummary = localModelInitialShearSummary( ...
    groups, result.mechanics.stressUnit);
result.config = config;
result.createdAt = datetime("now");

if numel(groupNames) == 2
    groupA = groups(1).population;
    groupA.name = groups(1).name;
    groupB = groups(2).population;
    groupB.name = groups(2).name;
    result.curveComparison = mechanics.statistics.compareGroupCurves( ...
        groupA, groupB, config);

    summary = analysis.summary;
    summary.Group = string(summary.(config.groupVariableName));
    result.metricComparison = mechanics.statistics.compareGroupMetrics( ...
        summary, groupNames(1), groupNames(2), config);
else
    result.curveComparison = struct();
    result.metricComparison = table();
end

if config.export.enabled
    result.outputFiles = mechanics.io.exportGroupComparison( ...
        result, config.export.outputFolder);
end
end

function metadata = localMechanicsMetadata(records)
metadata.strainMeasure = "";
metadata.stressMeasure = "";
metadata.strainUnit = "";
metadata.stressUnit = "";

for index = 1:numel(records)
    record = records(index);
    if record.status ~= "processed" || ~isfield(record, "specimen") || ...
            ~isfield(record.specimen, "processed")
        continue;
    end

    processed = record.specimen.processed;
    if isfield(processed, "mechanicsConfig")
        if isfield(processed.mechanicsConfig, "strainMeasure")
            metadata.strainMeasure = ...
                string(processed.mechanicsConfig.strainMeasure);
        end
        if isfield(processed.mechanicsConfig, "stressMeasure")
            metadata.stressMeasure = ...
                string(processed.mechanicsConfig.stressMeasure);
        end
    end
    if isfield(processed, "units")
        if isfield(processed.units, "strain")
            metadata.strainUnit = string(processed.units.strain);
        end
        if isfield(processed.units, "stress")
            metadata.stressUnit = string(processed.units.stress);
        end
    end
    break;
end
end

function testType = localTestType(records)
testType = "";
for index = 1:numel(records)
    record = records(index);
    if record.status ~= "processed" || ~isfield(record, "specimen") || ...
            ~isfield(record.specimen, "testType")
        continue;
    end
    testType = lower(string(record.specimen.testType));
    break;
end
end

function summary = localModelInitialShearSummary(groups, stressUnit)
groupCount = numel(groups);
group = strings(groupCount, 1);
specimenCount = zeros(groupCount, 1);
centralStatistic = strings(groupCount, 1);
initialShearModulus = nan(groupCount, 1);
unit = repmat(string(stressUnit), groupCount, 1);
models = strings(groupCount, 1);

for index = 1:groupCount
    group(index) = groups(index).name;
    population = groups(index).population;
    centralStatistic(index) = lower(string(population.config.centralStatistic));

    if ~isfield(population, "modelParameters") || ...
            ~isfield(population.modelParameters, "values") || ...
            isempty(population.modelParameters.values)
        continue;
    end

    values = population.modelParameters.values;
    parameterTable = table( ...
        string(values.SpecimenId), ...
        repmat(groups(index).name, height(values), 1), ...
        string(values.Model), ...
        string(values.Parameter), ...
        values.Value, ...
        'VariableNames', {'SpecimenId','Group','ModelName','Parameter','Value'});

    derived = mechanics.statistics.deriveInitialShearModulus(parameterTable);
    specimenCount(index) = height(derived.values);
    if isempty(derived.values)
        continue;
    end

    models(index) = strjoin(unique(derived.values.ModelName, "stable"), ", ");
    if centralStatistic(index) == "median"
        initialShearModulus(index) = derived.summary.Median;
    else
        initialShearModulus(index) = derived.summary.Mean;
    end
end

summary = table( ...
    group, specimenCount, centralStatistic, initialShearModulus, unit, models, ...
    'VariableNames', {'Group','SpecimenCount','CentralStatistic', ...
    'InitialShearModulus','Unit','Models'});
end
