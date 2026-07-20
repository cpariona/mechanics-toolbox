function tbl = getSheetTable(sheetData, sheetName)
% Gets a table from the sheetData cell array using a sheet name.
%
% Inputs:
%   sheetData - Cell array with sheet names and tables.
%   sheetName - Name of the requested sheet.
%
% Outputs:
%   tbl - Table from the requested sheet.

    idx = strcmp(sheetData(:,1), sheetName);

    if ~any(idx)
        error("Sheet '%s' not found.", sheetName);
    end

    tbl = sheetData{idx,2};
end