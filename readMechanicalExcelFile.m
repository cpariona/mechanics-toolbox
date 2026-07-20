function [sheetData, sheetNames] = readMechanicalExcelFile(filename)
% Reads a mechanical test Excel file into a cell array.
% Expected structure: parameters, results, statistics, and specimen sheets.
%
% Inputs:
%   filename - Full path to the Excel file.
%
% Outputs:
%   sheetData  - Cell array with sheet names and tables.
%   sheetNames - Cell array with Excel sheet names.

    sheetNames = sheetnames(filename);
    numSheets  = numel(sheetNames);
    sheetData  = cell(numSheets, 2);

    for i = 1:numSheets

        sheetData{i,1} = sheetNames{i};

        try
            if i == 1
                raw = readcell(filename, ...
                    'Sheet', sheetNames{i}, ...
                    'Range', 'A1:B20');

                raw(all(cellfun(@(x) all(ismissing(x)), raw), 2), :) = [];
                tbl = cell2table(raw);

            elseif i == 2 || i == 3
                opts = detectImportOptions(filename, 'Sheet', sheetNames{i});
                opts.DataRange = 'A3';
                opts.VariableNamesRange = 'A1';
                opts.PreserveVariableNames = true;

                tbl = readtable(filename, opts);

            else
                opts = detectImportOptions(filename, 'Sheet', sheetNames{i});
                opts.DataRange = 'A4';
                opts.VariableNamesRange = 'A2';
                opts.PreserveVariableNames = true;

                tbl = readtable(filename, opts);
            end

        catch ME
            warning("Error reading sheet '%s': %s", sheetNames{i}, ME.message);
            tbl = table();
        end

        sheetData{i,2} = tbl;
    end
end