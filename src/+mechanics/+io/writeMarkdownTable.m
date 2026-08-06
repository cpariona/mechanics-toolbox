function writeMarkdownTable(fileId, inputTable)
%WRITEMARKDOWNTABLE Write one table using the maintained Markdown contract.
arguments
    fileId (1,1) double
    inputTable table
end

variables = string(inputTable.Properties.VariableNames);
fprintf(fileId, "| %s |\n", char(strjoin(variables, " | ")));
fprintf(fileId, "|%s|\n", ...
    char(strjoin(repmat("---", 1, numel(variables)), "|")));
for row = 1:height(inputTable)
    values = strings(1, numel(variables));
    for column = 1:numel(variables)
        value = inputTable{row, column};
        if iscell(value)
            value = value{1};
        end
        values(column) = localText(value);
    end
    fprintf(fileId, "| %s |\n", char(strjoin(values, " | ")));
end
fprintf(fileId, "\n");
end

function output = localText(value)
if ismissing(value)
    output = "missing";
elseif islogical(value)
    output = string(value);
elseif isnumeric(value)
    if isempty(value) || ~isscalar(value)
        output = "";
    elseif isnan(value)
        output = "NaN";
    elseif isinf(value)
        output = string(value);
    else
        output = string(sprintf("%.6g", value));
    end
elseif isdatetime(value)
    output = string(value);
else
    output = replace(string(value), "|", "\\|");
end
end
