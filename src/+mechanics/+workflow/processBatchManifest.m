function batch = processBatchManifest(manifestInput, config)
%PROCESSBATCHMANIFEST Import and process specimens defined by a manifest.
arguments
    manifestInput
    config (1,1) struct = mechanics.config.batchProcessingConfig()
end

if istable(manifestInput)
    manifest = mechanics.workflow.validateBatchManifest(manifestInput);
elseif ischar(manifestInput) || isstring(manifestInput)
    manifest = mechanics.io.readBatchManifest(string(manifestInput));
else
    error("mechanics:workflow:InvalidManifestInput", ...
        "Manifest input must be a table or a manifest filename.");
end

records = repmat(localEmptyRecord(), height(manifest), 1);

for rowIndex = 1:height(manifest)
    records(rowIndex).rowIndex = rowIndex;
    records(rowIndex).specimenId = manifest.SpecimenId(rowIndex);
    records(rowIndex).filename = manifest.File(rowIndex);
    records(rowIndex).testType = manifest.TestType(rowIndex);

    if ~manifest.Include(rowIndex)
        records(rowIndex).status = "skipped";
        continue;
    end

    try
        importConfig = localImportConfig(config.importConfig, manifest, rowIndex);
        specimen = mechanics.io.readSpecimenTable( ...
            manifest.File(rowIndex), importConfig);

        geometry.initialLength = manifest.InitialLength(rowIndex);
        geometry.initialArea = manifest.InitialArea(rowIndex);

        processingConfig = config.processingConfig;
        processingConfig.testType = manifest.TestType(rowIndex);

        specimen = mechanics.workflow.processUniaxialSpecimen( ...
            specimen, geometry, processingConfig);

        specimen.testType = manifest.TestType(rowIndex);

        if config.fitting.enabled
            specimen.modelSelection = mechanics.fitting.fitAcrossWindows( ...
                config.fitting.modelNames, ...
                specimen.processed.strain, ...
                specimen.processed.stress, ...
                config.fitting.context, ...
                config.fitting.fitConfig, ...
                config.fitting.selectionConfig);
        end

        if config.exportResults
            specimen.outputFiles = mechanics.io.exportSpecimenResults( ...
                specimen, fullfile(config.outputFolder, specimen.id));
        end

        records(rowIndex).status = "processed";
        records(rowIndex).specimen = specimen;

    catch ME
        records(rowIndex).status = "failed";
        records(rowIndex).errorIdentifier = string(ME.identifier);
        records(rowIndex).errorMessage = string(ME.message);

        if ~config.continueOnError
            rethrow(ME);
        end
    end
end

batch.manifest = manifest;
batch.records = records;
batch.summary = mechanics.workflow.summarizeBatchResults(records);
batch.config = config;
batch.createdAt = datetime("now");
end

function importConfig = localImportConfig(baseConfig, manifest, rowIndex)
importConfig = baseConfig;
importConfig.specimenId = manifest.SpecimenId(rowIndex);
importConfig.sheet = manifest.Sheet(rowIndex);
importConfig.forceScale = manifest.ForceScale(rowIndex);
importConfig.displacementScale = manifest.DisplacementScale(rowIndex);
importConfig.timeScale = manifest.TimeScale(rowIndex);

forceColumn = strtrim(manifest.ForceColumn(rowIndex));
if strlength(forceColumn) > 0
    importConfig.forceColumns = unique( ...
        [forceColumn, string(importConfig.forceColumns)], "stable");
end

displacementColumn = strtrim(manifest.DisplacementColumn(rowIndex));
if strlength(displacementColumn) > 0
    importConfig.displacementColumns = unique( ...
        [displacementColumn, string(importConfig.displacementColumns)], "stable");
end

timeColumn = strtrim(manifest.TimeColumn(rowIndex));
if strlength(timeColumn) > 0
    importConfig.timeColumns = unique( ...
        [timeColumn, string(importConfig.timeColumns)], "stable");
end
end

function record = localEmptyRecord()
record.rowIndex = NaN;
record.specimenId = "";
record.filename = "";
record.testType = "";
record.status = "pending";
record.specimen = struct();
record.errorIdentifier = "";
record.errorMessage = "";
end
