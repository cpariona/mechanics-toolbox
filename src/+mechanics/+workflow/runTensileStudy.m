function study = runTensileStudy(filename, config)
%RUNTENSILESTUDY Execute extraction, specimen analysis, peak metrics, and population.
arguments
    filename (1,1) string
    config (1,1) struct = mechanics.config.tensileStudyConfig()
end

if ~isfile(filename)
    error("mechanics:workflow:StudyFileNotFound", ...
        "Input workbook does not exist: %s", filename);
end

dataset = mechanics.extraction.extractWorkbook(filename, config.extraction);
[dataset, exclusion] = localApplySpecimenConfiguration(dataset, config.specimens);
analysis = mechanics.workflow.analyzeExtractedDataset(dataset, config.datasetAnalysis);

if config.peakAnalysis.enabled
    analysis = mechanics.workflow.addPeakMetrics( ...
        analysis, config.peakAnalysis.config);
end

population = struct();
populationStatus = "disabled";
populationErrorIdentifier = "";
populationErrorMessage = "";
if config.population.enabled
    try
        population = mechanics.workflow.analyzeSpecimenPopulation( ...
            analysis, config.population.config);
        populationStatus = "completed";
    catch ME
        populationStatus = "failed";
        populationErrorIdentifier = string(ME.identifier);
        populationErrorMessage = string(ME.message);
        if ~config.population.continueOnError
            rethrow(ME);
        end
    end
end

study.sourceFile = filename;
study.dataset = dataset;
study.exclusion = exclusion;
study.analysis = analysis;
study.population = population;
study.populationStatus = populationStatus;
study.populationErrorIdentifier = populationErrorIdentifier;
study.populationErrorMessage = populationErrorMessage;
study.config = config;
study.provenance = mechanics.workflow.buildStudyProvenance(filename, analysis);
study.createdAt = datetime("now");

if config.export.enabled
    study.outputFiles = mechanics.io.exportTensileStudy(study, config.export);
end
end

function [dataset, exclusion] = localApplySpecimenConfiguration(dataset, specimenConfig)
specimens = dataset.specimens(:);
specimenCount = numel(specimens);
excludeIndices = unique(round(specimenConfig.excludeIndices(:)));
if any(~isfinite(excludeIndices)) || any(excludeIndices < 1) || ...
        any(excludeIndices > specimenCount)
    error("mechanics:workflow:InvalidExcludedSpecimenIndex", ...
        "Every excluded specimen index must identify an extracted specimen.");
end
excludedMask = false(specimenCount, 1);
excludedMask(excludeIndices) = true;
excludedSpecimens = specimens(excludedMask);

preloadOverrides = specimenConfig.preloadForceOverrides;
if isempty(preloadOverrides)
    preloadOverrides = nan(specimenCount, 1);
else
    preloadOverrides = preloadOverrides(:);
    if numel(preloadOverrides) ~= specimenCount
        error("mechanics:workflow:PreloadOverrideSizeMismatch", ...
            "preloadForceOverrides must be empty or contain one value per extracted specimen.");
    end
end
for index = 1:specimenCount
    if isfinite(preloadOverrides(index))
        specimens(index).processingOverrides.zeroReferenceMethod = "preload-threshold";
        specimens(index).processingOverrides.preloadForce = preloadOverrides(index);
    end
end

dataset.specimens = specimens(~excludedMask);
exclusion.indices = excludeIndices;
exclusion.specimenIds = strings(numel(excludedSpecimens), 1);
exclusion.sheetNames = strings(numel(excludedSpecimens), 1);
for index = 1:numel(excludedSpecimens)
    exclusion.specimenIds(index) = string(excludedSpecimens(index).id);
    if isfield(excludedSpecimens(index), "sheetName")
        exclusion.sheetNames(index) = string(excludedSpecimens(index).sheetName);
    end
end
exclusion.reason = string(specimenConfig.exclusionReason);
exclusion.count = numel(excludeIndices);
end
