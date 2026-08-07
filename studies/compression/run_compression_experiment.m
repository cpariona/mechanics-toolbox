%% 0. INITIALIZATION AND FILES
% Executable study driver for one ASTM D575 Method A compression experiment.
% Keep experiment-specific paths, exclusions, and settings in this file.

restoredefaultpath
clear classes
clear functions
clear
clc
close all

repositoryFolder = 'D:\Escritorio\mechanics-toolbox';
cd(repositoryFolder)
startup

inputFile = fullfile( ...
    repositoryFolder, "data", "raw", ...
    "Compression_ASTM_D575_ECOFLEX0050_test.xlsx");
outputFolder = fullfile( ...
    repositoryFolder, "results", "real-compression-study");

%% 1. STUDY CONFIGURATION
config = mechanics.config.compressionStudyConfig();

% Workbook extraction and ASTM D575 Method A cycle selection.
config.input.type = "workbook";
config.extraction.extractor = "auto";
config.specimen.cycle.selection = "last-complete-cycle";
config.specimen.cycle.branch = "loading";
config.specimen.cycle.loadingDirection = "increasing";
config.specimen.cycle.minimumCycleAmplitude = 0;
config.specimen.cycle.minimumObservations = 5;
config.specimen.cycle.smoothingFrameLength = 5;

% Mechanical zero. Method A does not use a preload threshold.
zeroConfig = config.specimen.processing.preprocessing.zeroReference;
zeroConfig.method = "first-sample";
zeroConfig.manualIndex = 1;
zeroConfig.trimBeforeReference = true;
config.specimen.processing.preprocessing.zeroReference = zeroConfig;

% Stored compression quantities retain physical negative signs.
mechanicsConfig = config.specimen.processing.mechanics;
mechanicsConfig.strainMeasure = "engineering";
mechanicsConfig.stressMeasure = "engineering";
mechanicsConfig.areaEvolution = "incompressible";
config.specimen.processing.mechanics = mechanicsConfig;

% Tangent-modulus analysis.
analysisConfig = config.specimen.processing.analysis;
analysisConfig.modulusMethod = "local-linear";
analysisConfig.derivativeWindowStrain = 0.02;
analysisConfig.summaryStrainRange = [-0.40, 0.00];
analysisConfig.modulusPlotStartStrain = NaN;
analysisConfig.modulusPlotAutomaticStartFraction = 0.01;
config.specimen.processing.analysis = analysisConfig;

% Explicit experiment-specific exclusions.
config.specimens.excludeIndices = [1; 2];
config.specimens.exclusionReason = ...
    "Initial thickness outside ASTM D575 tolerance";

% Constitutive fitting and model selection.
fitting = config.specimen.fitting;
fitting.enabled = true;
fitting.modelNames = [
    "neo-hookean"
    "mooney-rivlin"
    "yeoh-second-order"
    "yeoh-third-order"
];
fitting.context.deformationMeasure = "engineering-strain";
fitting.context.stressMeasure = "nominal";
fitting.fitConfig.numberOfStarts = 8;
fitting.fitConfig.randomSeed = 1;
fitting.fitConfig.maxIterations = 3000;
fitting.fitConfig.maxFunctionEvaluations = 10000;
fitting.fitConfig.functionTolerance = 1e-10;
fitting.fitConfig.parameterTolerance = 1e-10;
fitting.fitConfig.display = "off";
fitting.fitConfig.initialGuess = [];
fitting.fitConfig.lowerBounds = [];
fitting.fitConfig.upperBounds = [];
fitting.selectionConfig.windowFractions = [0.50, 0.75, 1.00];
fitting.selectionConfig.minimumObservations = 20;
fitting.selectionConfig.rankingMetric = "BIC";
fitting.selectionConfig.requireConvergence = true;

% Measurement Monte Carlo remains disabled until uncertainties are available.
mc = fitting.measurementMonteCarlo;
mc.enabled = false;
mc.sampleCount = 200;
mc.confidenceLevel = 0.95;
mc.randomSeed = 1;
mc.minimumSuccessfulFraction = 0.80;
mc.initialLengthStd = NaN; % mm
mc.initialAreaStd = NaN;   % mm^2
mc.forceStd = NaN;         % N
mc.displacementStd = NaN;  % mm
mc.refitNumberOfStarts = 2;
mc.storeFits = false;
fitting.measurementMonteCarlo = mc;
config.specimen.fitting = fitting;

% Pointwise geometry uncertainty remains disabled until h0 and A0 standard
% uncertainties are available.
geometryUncertainty = config.specimen.processing.uncertainty.geometry;
geometryUncertainty.enabled = false;
geometryUncertainty.initialLengthStd = NaN; % mm
geometryUncertainty.initialAreaStd = NaN;   % mm^2
config.specimen.processing.uncertainty.geometry = geometryUncertainty;

% Study processing owns all persisted study outputs. Per-specimen export stays
% disabled while specimens are assembled into the population result.
config.specimen.export.enabled = false;

% Population analysis.
population = config.population;
population.enabled = true;
population.continueOnError = true;
population.config.centralStatistic = "median";
population.config.strainGridPointCount = 201;
population.config.minimumSpecimens = 2;
population.config.bootstrap.enabled = true;
population.config.bootstrap.iterations = 2000;
population.config.bootstrap.confidenceLevel = 0.95;
population.config.bootstrap.randomSeed = 1;
population.config.export.enabled = false;
config.population = population;

% Automatic study bundle export.
config.export.enabled = true;
config.export.outputFolder = outputFolder;
config.export.saveStudyMat = true;
config.export.saveManifest = true;
config.export.saveSummary = true;
config.export.savePopulation = true;

%% 2. RUN THE COMPLETE COMPRESSION WORKFLOW
tic
study = mechanics.workflow.runCompressionStudy(inputFile, config);
elapsedTime = toc;

fprintf("Study completed in %.2f seconds.\n", elapsedTime)
disp(study.exclusion)
disp(study.manifest)
disp(study.analysis.summary)
fprintf("Population status: %s\n", char(study.populationStatus))

if study.populationStatus == "completed"
    disp(study.population.metrics)
    disp(study.population.modelParameters)
elseif study.populationStatus == "failed"
    fprintf(2, "Population error: %s\n", ...
        char(study.populationErrorMessage))
end

disp(study.outputFiles)

%% 3. MAINTAINED REPORT
reportConfig = mechanics.config.compressionStudyReportConfig();
reportConfig.outputFolder = fullfile(outputFolder, "report");
reportConfig.studyTitle = ...
    "ECOFLEX 00-50 — ASTM D575 Method A compression study";
reportFiles = mechanics.io.exportCompressionStudyReport( ...
    study, reportConfig);
disp(reportFiles)

%% 4. RESULTS AND DISTINCT INTERACTIVE DIAGNOSTICS
% Persistent workflow figures are owned by maintained exporters. Keep only
% experiment-inspection views that are not represented in those exports.
summaryTable = study.analysis.summary;
availableColumns = string(summaryTable.Properties.VariableNames);
requestedColumns = [
    "SpecimenId"
    "Status"
    "MaximumStrain"
    "MaximumStress"
    "MedianTangentModulus"
    "SelectedModel"
];
selectedColumns = requestedColumns( ...
    ismember(requestedColumns, availableColumns));
disp(summaryTable(:, cellstr(selectedColumns)))

records = study.analysis.records;
processedIndices = find(string({records.status}) == "processed");

if ~isempty(processedIndices)
    specimen = records(processedIndices(1)).specimen;

    % Complete instrument acquisition, including conditioning cycles.
    figure("Color", "w")
    plot(specimen.originalRaw.displacement, specimen.originalRaw.force, ...
        "LineWidth", 1.0)
    xlabel("Instrument displacement")
    ylabel("Instrument force")
    title("Original recorded compression cycles")
    grid on
    box on

    % Selected constitutive fit for one specimen remains an interactive view.
    if isfield(specimen, "modelSelection") && ...
            specimen.modelSelection.selection.hasEligibleModel
        modelStudy = specimen.modelSelection;
        bestModel = string(modelStudy.selection.bestModel);
        modelRecords = modelStudy.records;
        validMask = [modelRecords.succeeded] & ...
            string({modelRecords.modelName}) == bestModel;
        validRecords = modelRecords(validMask);
        if ~isempty(validRecords)
            [~, fullWindowIndex] = max([validRecords.windowFraction]);
            bestFit = validRecords(fullWindowIndex).fitResult;
            modelDefinition = mechanics.models.modelRegistry(bestFit.modelName);
            parameterTable = table( ...
                string(modelDefinition.parameterNames(:)), ...
                bestFit.parameters(:), ...
                'VariableNames', {'Parameter', 'Estimate'});
            disp("Selected model: " + modelDefinition.displayName)
            disp(parameterTable)
            disp(bestFit.metrics)
            mechanics.plotting.plotModelFit(bestFit);
        end
    end
end

%% 5. OPTIONAL COMPRESSION WORKFLOWS
% Optional workflows remain available for compatible datasets.
% Consensus-model population fitting is enabled for this experiment.
% Their exporters own all persistent figures and tabular/MAT outputs.
runFitDiagnostics = false;
runReliabilityAwareModelComparison = false;
runConsensusModelPopulation = true;
runGroupComparison = false;
runGroupParameterInference = false;
runConstitutiveStudyReport = false;

if ~isempty(processedIndices)
    optionalSpecimen = records(processedIndices(1)).specimen;
    optionalDeformation = optionalSpecimen.processed.strain;
    optionalStress = optionalSpecimen.processed.stress;
    optionalContext = config.specimen.fitting.context;
else
    optionalDeformation = [];
    optionalStress = [];
    optionalContext = struct();
end

if runFitDiagnostics
    fitDiagnostics = mechanics.workflow.runFitDiagnostics( ...
        "yeoh-third-order", optionalDeformation, optionalStress, optionalContext, ...
        mechanics.config.fittingConfig(), ...
        mechanics.config.fitDiagnosticsWorkflowConfig());
    disp(fitDiagnostics.reliability.componentSummary)
    disp(fitDiagnostics.reliability.status)
    fitDiagnosticFiles = mechanics.io.exportFitDiagnostics( ...
        fitDiagnostics, fullfile(outputFolder, "fit-diagnostics"));
    disp(fitDiagnosticFiles)
end

if runReliabilityAwareModelComparison
    modelComparison = mechanics.workflow.compareModelsWithDiagnostics( ...
        config.specimen.fitting.modelNames, ...
        optionalDeformation, optionalStress, optionalContext, ...
        mechanics.config.fittingConfig(), ...
        mechanics.config.modelComparisonWorkflowConfig());
    disp(modelComparison.summary)
    disp(modelComparison.selectedModelName)
    modelComparisonFiles = mechanics.io.exportModelComparison( ...
        modelComparison, fullfile(outputFolder, "model-comparison"));
    disp(modelComparisonFiles)
end

if runConsensusModelPopulation || ...
        runGroupParameterInference || runConstitutiveStudyReport
    comparisonSpecimens = struct([]);
    individualSelectedModels = strings(numel(processedIndices), 1);
    for outputIndex = 1:numel(processedIndices)
        processedSpecimen = records(processedIndices(outputIndex)).specimen;
        comparisonSpecimens(outputIndex).specimenId = ...
            string(processedSpecimen.id); %#ok<SAGROW>
        comparisonSpecimens(outputIndex).group = "Unassigned"; %#ok<SAGROW>
        comparisonSpecimens(outputIndex).deformation = ...
            processedSpecimen.processed.strain; %#ok<SAGROW>
        comparisonSpecimens(outputIndex).measuredStress = ...
            processedSpecimen.processed.stress; %#ok<SAGROW>
        comparisonSpecimens(outputIndex).context = ...
            config.specimen.fitting.context; %#ok<SAGROW>
        if isfield(processedSpecimen, "modelSelection") && ...
                processedSpecimen.modelSelection.selection.hasEligibleModel
            individualSelectedModels(outputIndex) = ...
                string(processedSpecimen.modelSelection.selection.bestModel);
        end
    end

    parameterBatch = mechanics.workflow.fitConsensusModelAcrossSpecimens( ...
        comparisonSpecimens, individualSelectedModels, ...
        config.specimen.fitting.modelNames, ...
        mechanics.config.fittingConfig(), ...
        mechanics.config.batchModelComparisonConfig());
    parameterPopulation = mechanics.workflow.summarizeSelectedParameters( ...
        parameterBatch, ...
        mechanics.config.selectedParameterPopulationConfig());
    disp(parameterBatch.modelSummary)
    disp("Consensus model: " + ...
        mechanics.models.modelRegistry(parameterBatch.consensusModelName).displayName)
    disp(parameterPopulation.parameterTable)
    disp(parameterPopulation.overallSummary)

    if runConsensusModelPopulation
        consensusModelFiles = ...
            mechanics.io.exportSelectedParameterPopulation( ...
            parameterPopulation, ...
            fullfile(outputFolder, "consensus-model-population"));
        disp(consensusModelFiles)
    end
end

if runGroupComparison
    % Replace the placeholder labels with the real experimental groups.
    groupAssignments = table( ...
        string(summaryTable.SpecimenId), ...
        repmat("Unassigned", height(summaryTable), 1), ...
        'VariableNames', {'SpecimenId', 'Group'});
    groupedAnalysis = mechanics.workflow.assignSpecimenGroups( ...
        study.analysis, groupAssignments);
    groupNames = unique(groupAssignments.Group, "stable");
    groupComparison = mechanics.workflow.analyzeGroupComparison( ...
        groupedAnalysis, groupNames, ...
        mechanics.config.groupComparisonConfig());
    disp(groupComparison.metricComparison)
    groupComparisonFiles = mechanics.io.exportGroupComparison( ...
        groupComparison, fullfile(outputFolder, "group-comparison"));
    disp(groupComparisonFiles)
end

if runGroupParameterInference
    parameterInference = ...
        mechanics.workflow.compareSelectedParametersBetweenGroups( ...
        parameterPopulation, ...
        mechanics.config.groupParameterInferenceConfig());
    disp(parameterInference.comparisonTable)
    inferenceFiles = mechanics.io.exportGroupParameterInference( ...
        parameterInference, ...
        fullfile(outputFolder, "group-parameter-inference"));
    disp(inferenceFiles)
end

if runConstitutiveStudyReport
    if ~exist("parameterInference", "var")
        parameterInference = struct();
    end
    constitutiveReportConfig = ...
        mechanics.config.constitutiveStudyReportConfig();
    constitutiveReportConfig.outputFolder = ...
        fullfile(outputFolder, "constitutive-study-report");
    constitutiveReportFiles = mechanics.io.exportConstitutiveStudyReport( ...
        parameterBatch, parameterPopulation, ...
        parameterInference, constitutiveReportConfig);
    disp(constitutiveReportFiles)
end

% Compare completed material or condition studies separately with:
% mechanics.workflow.compareCompressionStudies(...)
