function analysis = analyzeExtractedDataset(dataset, config)
%ANALYZEEXTRACTEDDATASET Segment, quality-check, process, and fit specimens.
arguments
    dataset (1,1) struct
    config (1,1) struct = mechanics.config.datasetAnalysisConfig()
end

dataset = mechanics.extraction.validateExtractedDataset(dataset);
sourceSpecimens = dataset.specimens(:);
records = repmat(localEmptyRecord(), numel(sourceSpecimens), 1);

for index = 1:numel(sourceSpecimens)
    specimen = sourceSpecimens(index);
    records(index).index = index;
    records(index).specimenId = string(specimen.id);
    if isfield(specimen, "sheetName")
        records(index).sheetName = string(specimen.sheetName);
    end

    try
        segmentation = mechanics.segmentation.segmentTensileCurve( ...
            specimen.raw, config.segmentation);
        records(index).segmentation = rmfield(segmentation, "analysisRaw");

        analysisSpecimen = specimen;
        analysisSpecimen.originalRaw = specimen.raw;
        analysisSpecimen.analysisRaw = segmentation.analysisRaw;
        analysisSpecimen.raw = segmentation.analysisRaw;
        analysisSpecimen.segmentation = records(index).segmentation;

        quality = mechanics.quality.assessSpecimenQuality( ...
            analysisSpecimen, config.quality);
        records(index).quality = quality;

        if config.quality.rejectFailedQuality && ~quality.passed
            records(index).status = "quality-failed";
            records(index).errorIdentifier = ...
                "mechanics:quality:QualityCriteriaFailed";
            records(index).errorMessage = sprintf( ...
                "Failed quality checks: %s.", ...
                char(strjoin(quality.failedChecks, ", ")));
            continue;
        end

        processedSpecimen = localProcessSpecimen( ...
            analysisSpecimen, config.processingConfig);

        processedSpecimen.raw = specimen.raw;
        processedSpecimen.originalRaw = specimen.raw;
        processedSpecimen.analysisRaw = segmentation.analysisRaw;
        processedSpecimen.segmentation = records(index).segmentation;

        if config.fitting.enabled
            processedSpecimen.modelSelection = ...
                mechanics.fitting.fitAcrossWindows( ...
                    config.fitting.modelNames, ...
                    processedSpecimen.processed.strain, ...
                    processedSpecimen.processed.stress, ...
                    config.fitting.context, ...
                    config.fitting.fitConfig, ...
                    config.fitting.selectionConfig);

            if localMonteCarloEnabled(config.fitting)
                selectedFit = localSelectedFit(processedSpecimen.modelSelection);
                processedSpecimen.measurementMonteCarloFit = ...
                    mechanics.fitting.measurementMonteCarloFitUncertainty( ...
                        processedSpecimen, selectedFit, ...
                        config.fitting.measurementMonteCarlo);
            end
        end

        if config.export.enabled
            specimenFolder = fullfile(config.export.outputFolder, ...
                localSafeName(processedSpecimen.id));
            processedSpecimen.outputFiles = ...
                mechanics.io.exportSpecimenResults( ...
                    processedSpecimen, specimenFolder);
        end

        records(index).status = "processed";
        records(index).specimen = processedSpecimen;

    catch ME
        records(index).status = "failed";
        records(index).errorIdentifier = string(ME.identifier);
        records(index).errorMessage = string(ME.message);
        if ~config.continueOnError
            rethrow(ME);
        end
    end
end

analysis.sourceDataset = dataset;
analysis.records = records;
analysis.summary = mechanics.workflow.summarizeDatasetAnalysis(records);
analysis.config = config;
analysis.createdAt = datetime("now");
end

function specimen = localProcessSpecimen(specimen, processingConfig)
geometry = specimen.geometry;
if ~isfield(geometry, "initialLength") || ...
        ~isscalar(geometry.initialLength) || ...
        ~isfinite(geometry.initialLength) || ...
        geometry.initialLength <= 0
    error("mechanics:workflow:MissingInitialLength", ...
        "Specimen %s does not define a positive initialLength.", ...
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

if isfield(specimen, "processingOverrides")
    overrides = specimen.processingOverrides;
    if isfield(overrides, "zeroReferenceMethod")
        processingConfig.preprocessing.zeroReference.method = ...
            string(overrides.zeroReferenceMethod);
    end
    if isfield(overrides, "preloadForce")
        processingConfig.preprocessing.zeroReference.preloadForce = ...
            overrides.preloadForce;
    end
end

specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, processingConfig);
end

function enabled = localMonteCarloEnabled(fittingConfig)
enabled = isfield(fittingConfig, "measurementMonteCarlo") && ...
    isfield(fittingConfig.measurementMonteCarlo, "enabled") && ...
    logical(fittingConfig.measurementMonteCarlo.enabled);
end

function fitResult = localSelectedFit(modelSelection)
if ~modelSelection.selection.hasEligibleModel
    error("mechanics:fitting:NoEligibleModelForMonteCarlo", ...
        "Measurement Monte Carlo requires an eligible selected model.");
end
bestModel = modelSelection.selection.bestModel;
records = modelSelection.records;
mask = [records.succeeded] & string({records.modelName}) == bestModel;
selected = records(mask);
if isempty(selected)
    error("mechanics:fitting:MissingSelectedFit", ...
        "The selected model does not contain a successful fit record.");
end
[~, index] = max([selected.windowFraction]);
fitResult = selected(index).fitResult;
end

function value = localSafeName(value)
value = regexprep(string(value), "[^A-Za-z0-9_-]", "_");
end

function record = localEmptyRecord()
record.index = NaN;
record.specimenId = "";
record.sheetName = "";
record.status = "pending";
record.segmentation = struct();
record.quality = struct();
record.specimen = struct();
record.errorIdentifier = "";
record.errorMessage = "";
end
