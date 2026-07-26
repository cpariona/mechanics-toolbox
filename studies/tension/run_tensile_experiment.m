%% 0. INITIALIZATION AND FILES
% Executable study driver for one tensile experiment.
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
    repositoryFolder, ...
    "data", ...
    "raw", ...
    "Tension_ASTM_D412_ECOFLEX0050_test.xlsx");

outputFolder = fullfile( ...
    repositoryFolder, ...
    "results", ...
    "real-tensile-study");

%% 1. STUDY CONFIGURATION
% This section contains the settings normally modified between studies.

config = mechanics.config.tensileStudyConfig();

% Workbook extraction.
% extractor:
%   "auto"    : detects the workbook format automatically.
%   registered extractor name: forces a specific supported format.
% defaultInitialLength: gauge length used when it is absent from the file.
config.extraction.extractor = "auto";
config.extraction.defaultInitialLength = 25; % mm

% Specimen selection. Indices follow the workbook extraction order.
% excludeIndices:
%   []          : includes all extracted specimens.
%   index vector: excludes the indicated specimens before analysis.
% exclusionReason: text stored in the study provenance.
config.specimens.excludeIndices = 1;
config.specimens.exclusionReason = ...
    "Manual exclusion after visual inspection";

% preloadForceOverrides:
%   []  : uses the global preload threshold for every specimen.
%   NaN : uses the global value for that specimen.
%   value in N: applies an individual preload threshold.
config.specimens.preloadForceOverrides = [];

% Preprocessing and mechanical zero.
% method:
%   "first-sample"      : first selected observation defines zero.
%   "preload-threshold" : zero starts when force exceeds preloadForce.
%   "manual-index"      : manualIndex defines the zero observation.
%   "none"              : preserves the original reference.
% sustainedPoints: consecutive samples required above the preload.
zeroConfig = ...
    config.datasetAnalysis.processingConfig.preprocessing.zeroReference;

zeroConfig.method = "preload-threshold";
zeroConfig.preloadForce = 0.10; % N
zeroConfig.sustainedPoints = 3;
zeroConfig.manualIndex = 1;

config.datasetAnalysis.processingConfig.preprocessing.zeroReference = ...
    zeroConfig;

% Stress and strain measures.
% strainMeasure:
%   "engineering" : epsilon = (L-L0)/L0.
%   "true"        : epsilon = log(L/L0).
% stressMeasure:
%   "engineering" : force divided by initial area.
%   "true"        : force divided by the configured current area.
% areaEvolution affects only true stress:
%   "incompressible" : A = A0/lambda.
%   "poisson-power"  : A = A0/lambda^(2*nu).
%   "measured-area"  : uses pointwise measured area.
mechanicsConfig = ...
    config.datasetAnalysis.processingConfig.mechanics;

mechanicsConfig.strainMeasure = "engineering";
mechanicsConfig.stressMeasure = "engineering";
mechanicsConfig.areaEvolution = "incompressible";

config.datasetAnalysis.processingConfig.mechanics = mechanicsConfig;

% Tangent-modulus analysis.
% modulusMethod:
%   "local-linear"      : local linear regression; robust default.
%   "local-quadratic"   : local quadratic regression.
%   "gradient-smoothed" : gradient after smoothing.
%   "gradient"          : direct numerical gradient.
% derivativeWindowStrain: strain width of the local derivative window.
% summaryStrainRange: strain interval used for reported mean and median.
analysisConfig = ...
    config.datasetAnalysis.processingConfig.analysis;

analysisConfig.modulusMethod = "local-linear";
analysisConfig.derivativeWindowStrain = 0.02;
analysisConfig.summaryStrainRange = [0.08, 0.98];

% Plot-only trimming of unstable leading derivative values.
% NaN uses the first 1% of the strain span. Set a finite strain to override.
analysisConfig.modulusPlotStartStrain = NaN;
analysisConfig.modulusPlotAutomaticStartFraction = 0.01;

config.datasetAnalysis.processingConfig.analysis = analysisConfig;

% Loading-curve segmentation.
% enabled:
%   true  : restricts analysis to the selected loading segment.
%   false : analyzes the complete processed curve.
% method:
%   "pre-peak" : keeps the loading branch up to a peak fraction.
segmentation = config.datasetAnalysis.segmentation;
segmentation.enabled = true;
segmentation.method = "pre-peak";
segmentation.analysisPeakFraction = 1.0;
segmentation.minimumPostPeakDropFraction = 0.20;
config.datasetAnalysis.segmentation = segmentation;

% Quality control. Failed specimens are rejected while the study continues.
quality = config.datasetAnalysis.quality;
quality.minimumObservations = 20;
quality.requireMonotonicDisplacement = false;
quality.maximumDisplacementReversalFraction = 0.05;
quality.minimumDisplacementRange = 0;
quality.minimumForceRange = 0;
quality.maximumNonfiniteFraction = 0;
quality.rejectFailedQuality = true;
config.datasetAnalysis.quality = quality;
config.datasetAnalysis.continueOnError = true;

% Constitutive fitting and model selection.
% modelNames:
%   "neo-hookean"   : one-parameter incompressible model.
%   "mooney-rivlin" : two-parameter incompressible model.
%   "yeoh"          : three-parameter incompressible model.
% deformationMeasure:
%   "engineering-strain", "true-strain", or "stretch".
% stressMeasure:
%   "nominal" or "cauchy".
fitting = config.datasetAnalysis.fitting;
fitting.enabled = true;
fitting.modelNames = [
    "neo-hookean"
    "mooney-rivlin"
    "yeoh"
];

fitting.context.deformationMeasure = "engineering-strain";
fitting.context.stressMeasure = "nominal";

% Numerical fitting options.
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

% Model-selection stability.
% rankingMetric: "BIC", "AIC", or "RMSE".
selection = fitting.selectionConfig;
selection.windowFractions = [0.50, 0.75, 1.00];
selection.minimumObservations = 20;
selection.rankingMetric = "BIC";
selection.requireConvergence = true;
selection.maximumRelativeParameterCV = 0.50;
fitting.selectionConfig = selection;

% Measurement Monte Carlo for fitted parameters.
% Keep disabled until supported standard uncertainties are available.
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

config.datasetAnalysis.fitting = fitting;

% Pointwise propagation of geometry uncertainty.
% Keep disabled until L0 and A0 standard uncertainties are available.
geometryUncertainty = ...
    config.datasetAnalysis.processingConfig.uncertainty.geometry;

geometryUncertainty.enabled = false;
geometryUncertainty.initialLengthStd = NaN; % mm
geometryUncertainty.initialAreaStd = NaN;   % mm^2

config.datasetAnalysis.processingConfig.uncertainty.geometry = ...
    geometryUncertainty;

% Peak and post-peak descriptors.
config.peakAnalysis.enabled = true;
peakConfig = config.peakAnalysis.config;
peakConfig.enabled = true;
peakConfig.integrateAbsoluteDisplacement = false;
peakConfig.minimumObservations = 3;
config.peakAnalysis.config = peakConfig;

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
config.population = population;

% Automatic study export.
config.export.enabled = true;
config.export.outputFolder = outputFolder;
config.export.saveAnalysisMat = true;
config.export.saveConfigurationMat = true;
config.export.saveTables = true;

%% 2. RUN THE COMPLETE TENSILE WORKFLOW
% Extraction, preprocessing, segmentation, fitting, peak metrics,
% population analysis, and configured exports are executed here.

tic
study = mechanics.workflow.runTensileStudy(inputFile, config);
elapsedTime = toc;

fprintf("Study completed in %.2f seconds.\n", elapsedTime)

studySummary = mechanics.workflow.summarizeTensileStudy(study);
disp(studySummary)
disp(study.analysis.summary)

if ~isempty(study.analysis.peakSummary)
    disp(study.analysis.peakSummary)
end

if study.populationStatus == "completed"
    disp(study.population.metrics)
end

% Generate the integrated Markdown report and report figures.
reportConfig = mechanics.config.studyReportConfig();
reportConfig.outputFolder = fullfile(outputFolder, "report");
reportConfig.studyTitle = "";

reportFiles = mechanics.io.exportTensileStudyReport( ...
    study, reportConfig);

disp(study.outputFiles)
disp(reportFiles)

%% 3. RESULTS AND PLOTS
% Display the main summaries and use maintained plotting entrypoints where
% available. The population plot remains local because the repository does
% not expose a maintained public plotting function for this result.

summaryTable = study.analysis.summary;
availableColumns = string(summaryTable.Properties.VariableNames);

requestedColumns = [
    "SpecimenId"
    "Status"
    "MaximumStrain"
    "MaximumStress"
    "MedianTangentModulus"
    "BestModel"
];

selectedColumns = requestedColumns( ...
    ismember(requestedColumns, availableColumns));

disp(summaryTable(:, cellstr(selectedColumns)))
disp(study.exclusion)

records = study.analysis.records;
processedMask = string({records.status}) == "processed";
processedIndices = find(processedMask);

% Inspect the first processed specimen.
if ~isempty(processedIndices)
    specimenIndex = processedIndices(1);
    record = records(specimenIndex);
    specimen = record.specimen;

    mechanics.plotting.plotStressStrain( ...
        specimen.processed, ...
        Title="Processed specimen: " + string(specimen.id), ...
        DisplayName="Experimental");

    figure("Color", "w")
    tiledlayout(1, 2, "TileSpacing", "compact", "Padding", "compact")

    nexttile
    plot( ...
        specimen.originalRaw.displacement, ...
        specimen.originalRaw.force, ...
        "LineWidth", 1.1)
    hold on
    plot( ...
        specimen.processed.displacement, ...
        specimen.processed.force, ...
        "LineWidth", 1.4)
    xlabel("Displacement")
    ylabel("Force")
    title("Raw and processed")
    legend("Raw", "Processed", "Location", "best")
    grid on
    box on

    nexttile
    tangent = specimen.analysis.tangentModulus;
    plot( ...
        tangent.strain, ...
        tangent.tangentModulusForPlot, ...
        "LineWidth", 1.4)
    xlabel("Engineering strain")
    ylabel("Tangent modulus")
    title("Tangent modulus")
    grid on
    box on

    if isfield(specimen, "modelSelection") && ...
            specimen.modelSelection.selection.hasEligibleModel

        modelStudy = specimen.modelSelection;
        bestModel = string(modelStudy.selection.bestModel);
        modelRecords = modelStudy.records;

        validMask = ...
            [modelRecords.succeeded] & ...
            string({modelRecords.modelName}) == bestModel;

        validRecords = modelRecords(validMask);

        if ~isempty(validRecords)
            [~, fullWindowIndex] = ...
                max([validRecords.windowFraction]);

            bestFit = validRecords(fullWindowIndex).fitResult;
            modelDefinition = ...
                mechanics.models.modelRegistry(bestFit.modelName);

            parameterTable = table( ...
                string(modelDefinition.parameterNames(:)), ...
                bestFit.parameters(:), ...
                'VariableNames', {'Parameter', 'Estimate'});

            disp("Selected model: " + bestModel)
            disp(parameterTable)
            disp(bestFit.metrics)

            mechanics.plotting.plotModelFit(bestFit);
        end
    end

    if isfield(specimen, "measurementMonteCarloFit")
        mcResult = specimen.measurementMonteCarloFit;
        mcParameterNames = string(mcResult.parameterNames);

        if ischar(mcResult.parameterNames)
            mcParameterNames = string({mcResult.parameterNames});
        end

        mcTable = table( ...
            mcParameterNames(:), ...
            mcResult.baseParameters(:), ...
            mcResult.parameterLower(:), ...
            mcResult.parameterMedian(:), ...
            mcResult.parameterUpper(:), ...
            'VariableNames', { ...
                'Parameter', ...
                'BaseEstimate', ...
                'Lower', ...
                'Median', ...
                'Upper'});

        disp(mcTable)

        fprintf( ...
            "Successful Monte Carlo refits: %.1f %%\n", ...
            100 * mcResult.successfulFraction)
    end
end

% Plot the population response. Kept local because no maintained public
% population-plotting entrypoint exists in the current repository.
if study.populationStatus == "completed"
    aggregate = study.population.curves;

    figure("Color", "w")
    hold on

    for index = 1:size(aggregate.stressMatrix, 2)
        plot( ...
            aggregate.strain, ...
            aggregate.stressMatrix(:, index), ...
            "LineWidth", 0.8, ...
            "HandleVisibility", "off")
    end

    finiteInterval = ...
        all(isfinite(aggregate.confidenceLower)) && ...
        all(isfinite(aggregate.confidenceUpper));

    if finiteInterval
        fill( ...
            [aggregate.strain; flipud(aggregate.strain)], ...
            [aggregate.confidenceLower; ...
             flipud(aggregate.confidenceUpper)], ...
            0.8 .* [1, 1, 1], ...
            "EdgeColor", "none", ...
            "FaceAlpha", 0.5, ...
            "DisplayName", sprintf( ...
                "%.0f%% bootstrap CI", ...
                100 * aggregate.config.bootstrap.confidenceLevel))
    end

    centralStatistic = string(aggregate.config.centralStatistic);

    if centralStatistic == "median" && ...
            isfield(aggregate, "medianStress")
        centralCurve = aggregate.medianStress;
        centralLabel = "Median";
    elseif isfield(aggregate, "centralStress")
        centralCurve = aggregate.centralStress;
        centralLabel = centralStatistic;
    else
        centralCurve = aggregate.meanStress;
        centralLabel = "Mean";
    end

    plot( ...
        aggregate.strain, ...
        centralCurve, ...
        "LineWidth", 2, ...
        "DisplayName", char(centralLabel))

    xlabel("Engineering strain")
    ylabel("Nominal stress")
    title("Population tensile response")
    legend("Location", "best")
    grid on
    box on
end

%% 4. OPTIONAL TENSILE WORKFLOWS
% These workflows are disabled by default. Enable only the analyses required
% for the current experiment and provide the indicated inputs.

runFitDiagnostics = false;
runReliabilityAwareModelComparison = false;
runSelectedParameterPopulation = true;
runGroupComparison = false;
runGroupParameterInference = false;
runConstitutiveStudyReport = false;
runBatchManifest = false; % Pending contract unification; do not enable yet.

% Use the first processed specimen as the default optional-analysis target.
if ~isempty(processedIndices)
    optionalRecord = records(processedIndices(1));
    optionalSpecimen = optionalRecord.specimen;
    optionalDeformation = optionalSpecimen.processed.strain;
    optionalStress = optionalSpecimen.processed.stress;
    optionalContext = config.datasetAnalysis.fitting.context;
else
    optionalSpecimen = struct();
    optionalDeformation = [];
    optionalStress = [];
    optionalContext = struct();
end

% Integrated fitting diagnostics for one chosen model and specimen.
if runFitDiagnostics
    diagnosticModel = "yeoh";
    diagnosticConfig = mechanics.config.fitDiagnosticsWorkflowConfig();

    fitDiagnostics = mechanics.workflow.runFitDiagnostics( ...
        diagnosticModel, optionalDeformation, optionalStress, ...
        optionalContext, mechanics.config.fittingConfig(), ...
        diagnosticConfig);

    disp(fitDiagnostics.reliability.componentSummary)
    disp(fitDiagnostics.reliability.status)
    mechanics.plotting.plotFitReliability(fitDiagnostics.reliability);
    mechanics.io.exportFitDiagnostics( ...
        fitDiagnostics, fullfile(outputFolder, "fit-diagnostics"));
end

% Reliability-aware comparison of candidate models for one specimen.
if runReliabilityAwareModelComparison
    comparisonConfig = mechanics.config.modelComparisonWorkflowConfig();

    modelComparison = mechanics.workflow.compareModelsWithDiagnostics( ...
        config.datasetAnalysis.fitting.modelNames, ...
        optionalDeformation, optionalStress, optionalContext, ...
        mechanics.config.fittingConfig(), comparisonConfig);

    disp(modelComparison.summary)
    disp(modelComparison.selectedModelName)
    mechanics.plotting.plotModelComparison(modelComparison);
    mechanics.io.exportModelComparison( ...
        modelComparison, fullfile(outputFolder, "model-comparison"));
end

% Batch comparison and population summary of selected-model parameters.
% Group labels default to "Unassigned"; replace them before group inference.
if runSelectedParameterPopulation || ...
        runGroupParameterInference || ...
        runConstitutiveStudyReport

    comparisonSpecimens = struct([]);
    outputIndex = 0;

    for index = processedIndices
        outputIndex = outputIndex + 1;
        processedSpecimen = records(index).specimen;

        comparisonSpecimens(outputIndex).specimenId = ...
            string(processedSpecimen.id); %#ok<SAGROW>
        comparisonSpecimens(outputIndex).group = ...
            "Unassigned"; %#ok<SAGROW>
        comparisonSpecimens(outputIndex).deformation = ...
            processedSpecimen.processed.strain; %#ok<SAGROW>
        comparisonSpecimens(outputIndex).measuredStress = ...
            processedSpecimen.processed.stress; %#ok<SAGROW>
        comparisonSpecimens(outputIndex).context = ...
            config.datasetAnalysis.fitting.context; %#ok<SAGROW>
    end

    batchConfig = mechanics.config.batchModelComparisonConfig();
    parameterBatch = mechanics.workflow.compareModelsAcrossSpecimens( ...
        comparisonSpecimens, ...
        config.datasetAnalysis.fitting.modelNames, ...
        mechanics.config.fittingConfig(), batchConfig);

    parameterPopulationConfig = ...
        mechanics.config.selectedParameterPopulationConfig();

    parameterPopulation = ...
        mechanics.workflow.summarizeSelectedParameters( ...
            parameterBatch, parameterPopulationConfig);

    disp(parameterPopulation.parameterTable)
    disp(parameterPopulation.overallSummary)
    disp(parameterPopulation.groupSummary)

    if runSelectedParameterPopulation
        mechanics.plotting.plotSelectedParameterPopulation( ...
            parameterPopulation);
        mechanics.io.exportSelectedParameterPopulation( ...
            parameterPopulation, ...
            fullfile(outputFolder, "selected-parameter-population"));
    end
end

% Descriptive comparison of user-defined specimen groups.
if runGroupComparison
    % Replace this table with the real experimental group assignment.
    groupAssignments = table( ...
        string(summaryTable.SpecimenId), ...
        repmat("Unassigned", height(summaryTable), 1), ...
        'VariableNames', {'SpecimenId', 'Group'});

    groupedAnalysis = mechanics.workflow.assignSpecimenGroups( ...
        study.analysis, groupAssignments);

    groupNames = unique(groupAssignments.Group, "stable");
    groupConfig = mechanics.config.groupComparisonConfig();

    groupComparison = mechanics.workflow.analyzeGroupComparison( ...
        groupedAnalysis, groupNames, groupConfig);

    disp(groupComparison.metricComparison)
    mechanics.plotting.plotGroupComparison(groupComparison);
    mechanics.io.exportGroupComparison( ...
        groupComparison, fullfile(outputFolder, "group-comparison"));
end

% Inferential comparison of homologous selected parameters between groups.
if runGroupParameterInference
    % Requires at least two real groups in comparisonSpecimens.
    inferenceConfig = mechanics.config.groupParameterInferenceConfig();

    parameterInference = ...
        mechanics.workflow.compareSelectedParametersBetweenGroups( ...
            parameterPopulation, inferenceConfig);

    disp(parameterInference.comparisonTable)
    mechanics.plotting.plotGroupParameterInference(parameterInference);
    mechanics.io.exportGroupParameterInference( ...
        parameterInference, ...
        fullfile(outputFolder, "group-parameter-inference"));
end

% Integrated constitutive report from batch selection, parameter population,
% and optional group inference.
if runConstitutiveStudyReport
    if ~exist("parameterInference", "var")
        parameterInference = struct();
    end

    constitutiveReportConfig = ...
        mechanics.config.constitutiveStudyReportConfig();

    constitutiveReportConfig.outputFolder = ...
        fullfile(outputFolder, "constitutive-study-report");

    constitutiveReportFiles = ...
        mechanics.io.exportConstitutiveStudyReport( ...
            parameterBatch, parameterPopulation, ...
            parameterInference, constitutiveReportConfig);

    disp(constitutiveReportFiles)
end

% Multiple files with one specimen per file are supported by
% processBatchManifest, but that workflow currently returns a batch contract
% rather than the tensile-study contract used above. Uniformization is
% intentionally deferred to the next development phase.
if runBatchManifest
    error("mechanics:studies:BatchManifestPending", ...
        ["Batch-manifest execution is pending contract unification. " ...
         "Keep this flag false until that migration is completed."]);
end
