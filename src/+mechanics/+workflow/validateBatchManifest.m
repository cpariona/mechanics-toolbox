function manifest = validateBatchManifest(manifest)
%VALIDATEBATCHMANIFEST Validate and normalize a specimen batch manifest.
arguments
    manifest table
end

requiredVariables = ["File", "SpecimenId", "InitialLength", "InitialArea"];
availableVariables = string(manifest.Properties.VariableNames);

if ~all(ismember(requiredVariables, availableVariables))
    missingVariables = requiredVariables(~ismember(requiredVariables, availableVariables));
    error("mechanics:workflow:InvalidManifest", ...
        "Manifest is missing required columns: %s.", ...
        strjoin(missingVariables, ", "));
end

rowCount = height(manifest);
manifest.File = string(manifest.File);
manifest.SpecimenId = string(manifest.SpecimenId);

if ~isnumeric(manifest.InitialLength) || ~isnumeric(manifest.InitialArea)
    error("mechanics:workflow:InvalidManifestGeometry", ...
        "InitialLength and InitialArea must be numeric.");
end

if any(~isfinite(manifest.InitialLength)) || ...
        any(manifest.InitialLength <= 0) || ...
        any(~isfinite(manifest.InitialArea)) || ...
        any(manifest.InitialArea <= 0)
    error("mechanics:workflow:InvalidManifestGeometry", ...
        "InitialLength and InitialArea must be positive finite values.");
end

manifest = localAddDefault(manifest, "Include", true(rowCount, 1));
manifest = localAddDefault(manifest, "Sheet", ones(rowCount, 1));
manifest = localAddDefault(manifest, "ForceScale", ones(rowCount, 1));
manifest = localAddDefault(manifest, "DisplacementScale", ones(rowCount, 1));
manifest = localAddDefault(manifest, "TimeScale", ones(rowCount, 1));
manifest = localAddDefault(manifest, "CurrentAreaScale", ones(rowCount, 1));
manifest = localAddDefault(manifest, "ForceColumn", strings(rowCount, 1));
manifest = localAddDefault(manifest, "DisplacementColumn", strings(rowCount, 1));
manifest = localAddDefault(manifest, "TimeColumn", strings(rowCount, 1));
manifest = localAddDefault(manifest, "CurrentAreaColumn", strings(rowCount, 1));
manifest = localAddDefault(manifest, "TestType", repmat("tension", rowCount, 1));

manifest.Include = localToLogical(manifest.Include);
manifest.ForceColumn = string(manifest.ForceColumn);
manifest.DisplacementColumn = string(manifest.DisplacementColumn);
manifest.TimeColumn = string(manifest.TimeColumn);
manifest.CurrentAreaColumn = string(manifest.CurrentAreaColumn);
manifest.TestType = lower(string(manifest.TestType));

numericVariables = ["Sheet", "ForceScale", "DisplacementScale", ...
    "TimeScale", "CurrentAreaScale"];
for variableName = numericVariables
    values = manifest.(variableName);
    if ~isnumeric(values) || any(~isfinite(values))
        error("mechanics:workflow:InvalidManifest", ...
            "Manifest column %s must contain finite numeric values.", ...
            variableName);
    end
end

if any(strlength(strtrim(manifest.File)) == 0)
    error("mechanics:workflow:InvalidManifest", ...
        "Every included manifest row must define a file.");
end

if any(strlength(strtrim(manifest.SpecimenId)) == 0)
    error("mechanics:workflow:InvalidManifest", ...
        "Every manifest row must define a SpecimenId.");
end

supportedTestTypes = ["tension", "compression"];
if any(~ismember(manifest.TestType, supportedTestTypes))
    error("mechanics:workflow:UnknownTestType", ...
        "TestType must be tension or compression.");
end
end

function logicalValues = localToLogical(values)
if islogical(values)
    logicalValues = values;
    return;
end

if isnumeric(values)
    if any(~ismember(values, [0, 1]))
        error("mechanics:workflow:InvalidManifestInclude", ...
            "Include numeric values must be 0 or 1.");
    end
    logicalValues = logical(values);
    return;
end

textValues = lower(strtrim(string(values)));
trueValues = ["true", "1", "yes", "y", "si", "sí"];
falseValues = ["false", "0", "no", "n"];

isTrue = ismember(textValues, trueValues);
isFalse = ismember(textValues, falseValues);

if any(~isTrue & ~isFalse)
    invalidValues = unique(textValues(~isTrue & ~isFalse));
    error("mechanics:workflow:InvalidManifestInclude", ...
        "Include contains unsupported values: %s.", ...
        strjoin(invalidValues, ", "));
end

logicalValues = isTrue;
end

function tableValue = localAddDefault(tableValue, variableName, defaultValue)
if ~ismember(variableName, string(tableValue.Properties.VariableNames))
    tableValue.(variableName) = defaultValue;
end
end
