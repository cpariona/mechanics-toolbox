function detected = detectZwickD412Workbook(filename, config)
%DETECTZWICKD412WORKBOOK Detect a Zwick/Roell D412-style workbook.
arguments
    filename (1,1) string
    config (1,1) struct
end

try
    names = string(sheetnames(filename));
catch
    detected = false;
    return;
end

hasResults = any(strcmpi(names, string(config.zwick.resultsSheet)));
matchesSpecimen = ~cellfun( ...
    @isempty, ...
    regexp(cellstr(names), char(config.zwick.specimenSheetPattern), "once"));

detected = hasResults && any(matchesSpecimen);
end
