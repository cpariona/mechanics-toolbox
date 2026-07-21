function resolvedName = resolveColumnName(tableVariableNames, candidates, required)
%RESOLVECOLUMNNAME Resolve a table variable using exact or normalized aliases.
arguments
    tableVariableNames
    candidates string
    required (1,1) logical = true
end

variableNames = string(tableVariableNames);
candidates = candidates(:);

resolvedName = "";
for i = 1:numel(candidates)
    exactIndex = find(strcmp(variableNames, candidates(i)), 1);
    if ~isempty(exactIndex)
        resolvedName = variableNames(exactIndex);
        return;
    end
end

normalizedVariables = arrayfun( ...
    @mechanics.io.normalizeColumnName, variableNames);
normalizedCandidates = arrayfun( ...
    @mechanics.io.normalizeColumnName, candidates);

for i = 1:numel(normalizedCandidates)
    normalizedIndex = find( ...
        normalizedVariables == normalizedCandidates(i), 1);
    if ~isempty(normalizedIndex)
        resolvedName = variableNames(normalizedIndex);
        return;
    end
end

if required
    error("mechanics:io:MissingColumn", ...
        "None of the requested columns were found: %s. Available columns: %s.", ...
        strjoin(candidates, ", "), strjoin(variableNames, ", "));
end
end
