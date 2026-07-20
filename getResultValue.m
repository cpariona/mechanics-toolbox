function value = getResultValue(resultsTbl, sheetName, variableName)
% Gets a scalar value from the results table for one specimen.
% The first column is assumed to contain the specimen sheet name.
%
% Inputs:
%   resultsTbl   - Results table from the Excel file.
%   sheetName    - Specimen sheet name.
%   variableName - Requested variable name.
%
% Outputs:
%   value - Requested scalar value.

    specimenCol = string(resultsTbl{:,1});
    rowIdx = strcmp(strtrim(specimenCol), sheetName);

    if ~any(rowIdx)
        error("Specimen '%s' not found in Results sheet.", sheetName);
    end

    varIdx = findVariableIndex(resultsTbl, variableName);
    value = resultsTbl{rowIdx, varIdx};

    if iscell(value)
        value = value{1};
    end
end