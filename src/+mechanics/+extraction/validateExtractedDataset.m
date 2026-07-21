function dataset = validateExtractedDataset(dataset)
%VALIDATEEXTRACTEDDATASET Validate the normalized extraction contract.
arguments
    dataset (1,1) struct
end

if ~isfield(dataset, "specimens") || isempty(dataset.specimens)
    error("mechanics:extraction:InvalidDataset", ...
        "Extracted dataset must contain at least one specimen.");
end

requiredSpecimenFields = ["id", "raw", "geometry", "source"];

for index = 1:numel(dataset.specimens)
    specimen = dataset.specimens(index);

    if ~all(isfield(specimen, requiredSpecimenFields))
        error("mechanics:extraction:InvalidSpecimen", ...
            "Every specimen must contain id, raw, geometry, and source.");
    end

    if ~isfield(specimen.raw, "force") || ...
            ~isfield(specimen.raw, "displacement")
        error("mechanics:extraction:InvalidSpecimen", ...
            "Every specimen must contain raw.force and raw.displacement.");
    end

    if numel(specimen.raw.force) ~= numel(specimen.raw.displacement)
        error("mechanics:extraction:SizeMismatch", ...
            "Specimen %s has incompatible force and displacement sizes.", ...
            specimen.id);
    end

    if isempty(specimen.raw.force)
        error("mechanics:extraction:EmptySpecimen", ...
            "Specimen %s does not contain finite observations.", ...
            specimen.id);
    end
end
end
