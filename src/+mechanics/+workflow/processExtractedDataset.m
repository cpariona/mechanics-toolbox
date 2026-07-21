function processedDataset = processExtractedDataset(dataset, processingConfig)
%PROCESSEXTRACTEDDATASET Process all specimens from an extracted dataset.
arguments
    dataset (1,1) struct
    processingConfig (1,1) struct = mechanics.config.tensionConfig()
end

dataset = mechanics.extraction.validateExtractedDataset(dataset);
sourceSpecimens = dataset.specimens;
processedCells = cell(size(sourceSpecimens));

for index = 1:numel(sourceSpecimens)
    specimen = sourceSpecimens(index);
    geometry = specimen.geometry;

    if ~isfield(geometry, "initialLength") || ...
            ~isscalar(geometry.initialLength) || ...
            ~isfinite(geometry.initialLength) || ...
            geometry.initialLength <= 0
        error("mechanics:workflow:MissingInitialLength", ...
            ['Specimen %s does not define a positive initialLength. ' ...
             'Set config.defaultInitialLength during extraction or ' ...
             'assign specimen.geometry.initialLength before processing.'], ...
            char(string(specimen.id)));
    end

    if ~isfield(geometry, "initialArea") || ...
            ~isscalar(geometry.initialArea) || ...
            ~isfinite(geometry.initialArea) || ...
            geometry.initialArea <= 0
        error("mechanics:workflow:MissingInitialArea", ...
            "Specimen %s does not define a positive initialArea.", ...
            char(string(specimen.id)));
    end

    processedCells{index} = ...
        mechanics.workflow.processUniaxialSpecimen( ...
            specimen, geometry, processingConfig);
end

processedSpecimens = [processedCells{:}];
processedSpecimens = reshape(processedSpecimens, size(sourceSpecimens));

processedDataset = dataset;
processedDataset.specimens = processedSpecimens;
processedDataset.processingConfig = processingConfig;
processedDataset.processedAt = datetime("now");
processedDataset.summary = ...
    mechanics.workflow.summarizeExtractedDataset(processedDataset);
end
