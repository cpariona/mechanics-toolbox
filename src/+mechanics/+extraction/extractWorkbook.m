function dataset = extractWorkbook(filename, config)
%EXTRACTWORKBOOK Extract a normalized dataset from an original workbook.
arguments
    filename (1,1) string
    config (1,1) struct = mechanics.config.workbookExtractionConfig()
end

if ~isfile(filename)
    error("mechanics:extraction:FileNotFound", ...
        "Input workbook does not exist: %s", filename);
end

if ~isempty(config.customExtractor)
    if ~isa(config.customExtractor, "function_handle")
        error("mechanics:extraction:InvalidCustomExtractor", ...
            "customExtractor must be a function handle.");
    end
    dataset = config.customExtractor(filename, config);
    dataset = mechanics.extraction.validateExtractedDataset(dataset);
    return;
end

requestedExtractor = lower(string(config.extractor));

if requestedExtractor == "auto"
    names = mechanics.extraction.listExtractors();
    selected = "";

    for index = 1:numel(names)
        extractor = mechanics.extraction.extractorRegistry(names(index));
        if extractor.detect(filename, config)
            selected = extractor.name;
            break;
        end
    end

    if strlength(selected) == 0
        error("mechanics:extraction:NoCompatibleExtractor", ...
            "No compatible extractor was found for %s.", filename);
    end
else
    selected = requestedExtractor;
end

extractor = mechanics.extraction.extractorRegistry(selected);
dataset = extractor.extract(filename, config);
dataset.extractor.name = extractor.name;
dataset.extractor.description = extractor.description;
dataset = mechanics.extraction.validateExtractedDataset(dataset);
end
