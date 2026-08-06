function tests = test_markdown_table_serialization
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testWritesCanonicalScalarValues(testCase)
inputTable = table( ...
    ["alpha|beta"; missing], ...
    [1.23456789; NaN], ...
    [true; false], ...
    [Inf; -Inf], ...
    'VariableNames', {'Name','Estimate','Accepted','Limit'});

content = localWriteAndRead(inputTable);
expected = strjoin([ ...
    "| Name | Estimate | Accepted | Limit |"
    "|---|---|---|---|"
    "| alpha\|beta | 1.23457 | true | Inf |"
    "| missing | NaN | false | -Inf |"
    ""
    ], newline);

verifyEqual(testCase, string(content), expected);
end

function testWritesDatetimeAndScalarCellValues(testCase)
timestamp = datetime(2026, 8, 6, 12, 30, 0);
inputTable = table(timestamp, {"cell|value"}, ...
    'VariableNames', {'CreatedAt','Description'});

content = localWriteAndRead(inputTable);
expected = strjoin([ ...
    "| CreatedAt | Description |"
    "|---|---|"
    "| " + string(timestamp) + " | cell\|value |"
    ""
    ], newline);

verifyEqual(testCase, string(content), expected);
end

function content = localWriteAndRead(inputTable)
filename = string(tempname) + ".md";
cleanup = onCleanup(@() localDelete(filename)); %#ok<NASGU>
fileId = fopen(filename, "w");
if fileId < 0
    error("mechanics:tests:TemporaryFileOpenFailed", ...
        "Could not open temporary Markdown file.");
end
fileCleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
mechanics.io.writeMarkdownTable(fileId, inputTable);
clear fileCleanup
content = fileread(filename);
end

function localDelete(filename)
if isfile(filename)
    delete(filename);
end
end
