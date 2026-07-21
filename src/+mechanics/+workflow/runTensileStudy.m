function study = runTensileStudy(filename, config)
%RUNTENSILESTUDY Execute extraction, specimen analysis, fracture, and population.
arguments
    filename (1,1) string
    config (1,1) struct = mechanics.config.tensileStudyConfig()
end

if ~isfile(filename)
    error("mechanics:workflow:StudyFileNotFound", ...
        "Input workbook does not exist: %s", filename);
end

dataset = mechanics.extraction.extractWorkbook(filename, config.extraction);
analysis = mechanics.workflow.analyzeExtractedDataset( ...
    dataset, config.datasetAnalysis);

if config.fracture.enabled
    analysis = mechanics.workflow.addFractureMetrics( ...
        analysis, config.fracture.config);
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
