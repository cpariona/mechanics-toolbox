function extractor = extractorRegistry(name)
%EXTRACTORREGISTRY Return metadata for a registered workbook extractor.
arguments
    name (1,1) string
end

normalizedName = lower(strtrim(name));

switch normalizedName
    case {"zwick-d412", "zwick", "zwick-roell"}
        extractor.name = "zwick-d412";
        extractor.detect = @mechanics.extraction.detectZwickD412Workbook;
        extractor.extract = @mechanics.extraction.extractZwickD412Workbook;
        extractor.description = ...
            "Zwick/Roell workbook with Resultados and Probeta sheets.";

    case {"generic-table", "generic"}
        extractor.name = "generic-table";
        extractor.detect = @(filename, config) true;
        extractor.extract = @mechanics.extraction.extractGenericTableWorkbook;
        extractor.description = ...
            "Single-sheet table using the configurable table importer.";

    otherwise
        error("mechanics:extraction:UnknownExtractor", ...
            "Unknown workbook extractor: %s", name);
end
end
