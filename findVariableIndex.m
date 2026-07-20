function varIdx = findVariableIndex(tbl, variableName, throwError)
% Finds a variable index in a table using exact or normalized matching.
%
% Inputs:
%   tbl          - Input table.
%   variableName - Requested variable name.
%   throwError   - Logical flag to throw an error if not found.
%
% Outputs:
%   varIdx - Variable index.

    if nargin < 3
        throwError = true;
    end

    varNames = tbl.Properties.VariableNames;

    varIdx = find(strcmp(varNames, variableName), 1);

    if ~isempty(varIdx)
        return;
    end

    normTarget = normalizeName(variableName);
    normVars = cellfun(@normalizeName, varNames, 'UniformOutput', false);

    varIdx = find(strcmp(normVars, normTarget), 1);

    if isempty(varIdx) && throwError
        error("Variable '%s' not found. Available variables are: %s", ...
            variableName, strjoin(varNames, ', '));
    end
end