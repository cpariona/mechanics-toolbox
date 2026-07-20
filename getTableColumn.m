function col = getTableColumn(tbl, possibleNames)
% Gets a table column using one of several possible names.
%
% Inputs:
%   tbl           - Input table.
%   possibleNames - Cell array with possible column names.
%
% Outputs:
%   col - Requested column data.

    varIdx = [];

    for i = 1:numel(possibleNames)
        varIdx = findVariableIndex(tbl, possibleNames{i}, false);

        if ~isempty(varIdx)
            break;
        end
    end

    if isempty(varIdx)
        error("None of these columns were found: %s", strjoin(possibleNames, ', '));
    end

    col = tbl{:, varIdx};
end