function result = deriveInitialShearModulus(parameterTable, config)
%DERIVEINITIALSHEARMODULUS Derive small-strain shear modulus by specimen.
arguments
    parameterTable table
    config (1,1) struct = mechanics.config.selectedParameterPopulationConfig()
end

required = ["SpecimenId","Group","ModelName","Parameter","Value"];
if ~all(ismember(required, string(parameterTable.Properties.VariableNames)))
    error("mechanics:statistics:InvalidSelectedParameterTable", ...
        "Selected-parameter table is missing required variables.");
end

specimenIds = unique(parameterTable.SpecimenId, "stable");
rowSpecimen = strings(0,1);
rowGroup = strings(0,1);
rowModel = strings(0,1);
rowValue = zeros(0,1);
errorSpecimen = strings(0,1);
errorIdentifier = strings(0,1);
errorMessage = strings(0,1);

for index = 1:numel(specimenIds)
    specimenId = specimenIds(index);
    rows = parameterTable(parameterTable.SpecimenId == specimenId, :);
    try
        models = unique(rows.ModelName);
        if numel(models) ~= 1
            error("mechanics:statistics:MultipleSelectedModels", ...
                "Each specimen must contain parameters from one selected model.");
        end
        modelName = lower(string(models));
        value = localInitialShearModulus(rows, modelName);
        if config.requireFiniteParameters && ~isfinite(value)
            error("mechanics:statistics:NonfiniteInitialShearModulus", ...
                "Derived initial shear modulus must be finite.");
        end

        rowSpecimen(end+1,1) = specimenId; %#ok<AGROW>
        rowGroup(end+1,1) = rows.Group(1); %#ok<AGROW>
        rowModel(end+1,1) = modelName; %#ok<AGROW>
        rowValue(end+1,1) = value; %#ok<AGROW>
    catch ME
        errorSpecimen(end+1,1) = specimenId; %#ok<AGROW>
        errorIdentifier(end+1,1) = string(ME.identifier); %#ok<AGROW>
        errorMessage(end+1,1) = string(ME.message); %#ok<AGROW>
        if ~config.continueOnExtractionError
            rethrow(ME);
        end
    end
end

values = table(rowSpecimen, rowGroup, rowModel, rowValue, ...
    'VariableNames', {'SpecimenId','Group','ModelName','InitialShearModulus'});
errors = table(errorSpecimen, errorIdentifier, errorMessage, ...
    'VariableNames', {'SpecimenId','ErrorIdentifier','ErrorMessage'});

result.values = values;
result.summary = localSummary(values, config);
result.errors = errors;
result.specimenCount = height(values);
end

function value = localInitialShearModulus(rows, modelName)
switch modelName
    case "neo-hookean"
        value = localParameter(rows, "mu");
    case "mooney-rivlin"
        value = 2 .* (localParameter(rows, "C10") + ...
            localParameter(rows, "C01"));
    case "yeoh"
        value = 2 .* localParameter(rows, "C10");
    otherwise
        error("mechanics:statistics:UnsupportedInitialShearModel", ...
            "Initial shear modulus is not defined for selected model: %s", ...
            modelName);
end
end

function value = localParameter(rows, parameterName)
match = strcmpi(rows.Parameter, parameterName);
if nnz(match) ~= 1
    error("mechanics:statistics:MissingInitialShearParameter", ...
        "Expected exactly one %s parameter for the selected model.", ...
        parameterName);
end
value = rows.Value(match);
end

function summary = localSummary(values, config)
if isempty(values)
    summary = table(0, NaN, NaN, NaN, NaN, NaN, false, ...
        'VariableNames', {'SpecimenCount','Mean','StandardDeviation', ...
        'Median','Minimum','Maximum','MeetsMinimumCount'});
    return;
end
x = values.InitialShearModulus;
count = numel(x);
meetsMinimumCount = count >= config.minimumSpecimensPerSummary;
standardDeviation = std(x,0);
if ~meetsMinimumCount
    standardDeviation = NaN;
end
summary = table(count, mean(x), standardDeviation, median(x), min(x), max(x), ...
    meetsMinimumCount, ...
    'VariableNames', {'SpecimenCount','Mean','StandardDeviation', ...
    'Median','Minimum','Maximum','MeetsMinimumCount'});
end