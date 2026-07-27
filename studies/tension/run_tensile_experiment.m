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
    repositoryFolder, "data", "raw", ...
    "Tension_ASTM_D412_ECOFLEX0050_test.xlsx");
outputFolder = fullfile( ...
    repositoryFolder, "results", "real-tensile-study");

%% 1. STUDY CONFIGURATION
config = mechanics.config.tensileStudyConfig();

% Workbook extraction.
config.extraction.extractor = "auto";
config.extraction.defaultInitialLength = 25; % mm

% Specimen selection. Indices follow workbook extraction order.
config.specimens.excludeIndices = 1;
config.specimens.exclusionReason = ...
    "Manual exclusion after visual inspection";
config.specimens.preloadForceOverrides = [];

% Mechanical zero.
zeroConfig = ...
    config.datasetAnalysis.processingConfig.preprocessing.zeroReference;
zeroConfig.method = "preload-threshold";
zeroConfig.preloadForce = 0.10; % N
zeroConfig.sustainedPoints = 3;
zeroConfig.manualIndex = 1;
config.datasetAnalysis.processingConfig.preprocessing.zeroReference = ...
    zeroConfig;

% Stress and strain measures.
mechanicsConfig = config.datasetAnalysis.processingConfig.mechanics;
mechanicsConfig.strainMeasure = "engineering";
mechanicsConfig.stressMeasure = "engineering";
mechanicsConfig.areaEvolution = "incompressible";
config.datasetAnalysis.processingConfig.mechanics = mechanicsConfig;

% Tangent-modulus analysis.
analysisConfig = config.datasetAnalysis.processingConfig.analysis;
analysisConfig.modulusMethod = "local-linear";
analysisConfig.derivativeWindowStrain = 0.02;
analysisConfig.summaryStrainRange = [0.08, 0.98];
analysisConfig.modulusPlotStartStrain = NaN;
analysisConfig.modulusPlotAutomaticStartFraction = 0.01;
config.datasetAnalysis.processingConfig.analysis = analysisConfig;

% Loading-curve segmentation.
segmentation = config.datasetAnalysis.segmentation;
segmentation.enabled = true;
segmentation.method = "pre-peak";
segmentation.analysisPeakFraction = 1.0;
segmentation.minimumPostPeakDropFraction = 0.20;
config.datasetAnalysis.segmentation = segmentation;

% Quality control.
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
fitting = config.datasetAnalysis.fitting;
fitting.enabled = true;
fitting.modelNames = [
    "neo-hookean"
    "mooney-rivlin"
    "yeoh"
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
fitting.selectionConfig.maximumRelativeParameterCV = 0.50;

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
config.datasetAnalysis.fitting = fitting;

% Pointwise geometry uncertainty remains disabled until L0 and A0 standard
% uncertainties are available.
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

% Generate the integrated Markdown report and maintained PNG/FIG pairs.
reportConfig = mechanics.config.studyReportConfig();
reportConfig.outputFolder = fullfile(outputFolder, "report");
reportConfig.studyTitle = "";
reportFiles = mechanics.io.exportTensileStudyReport(study, reportConfig);
disp(study.outputFiles)
disp(reportFiles)

%% 3. RESULTS AND DISTINCT INTERACTIVE DIAGNOSTICS
% Report figures already cover specimen stress-strain curves, the population
% response, peak metrics, tangent modulus, and zero-reference diagnostics.
% Keep only interactive views that add information not present in that report.
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
processedIndices = find(string({records.status}) == "processed");

if ~isempty(processedIndices)
    specimen = records(processedIndices(1)).specimen;

    % Distinct preprocessing diagnostic: complete original acquisition versus
    % the final selected and zero-referenced curve.
    figure("Color", "w")
    hold on
    plot(specimen.originalRaw.displacement, specimen.originalRaw.force, ...
        "LineWidth", 1.0, "DisplayName", "Original acquisition")
    plot(specimen.processed.displacement, specimen.processed.force, ...
        "LineWidth", 1.4, "DisplayName", "Processed curve")
    xlabel("Displacement")
    ylabel("Force")
    title("Original and processed tensile signals")
    legend("Location", "best")
    grid on
    box on

    % Distinct model diagnostic: the study report does not include the
    % selected constitutive fit for an individual specimen.
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
            'VariableNames', {'Parameter', 'BaseEstimate', ...
            'Lower', 'Median', 'Upper'});
        disp(mcTable)
        fprintf("Successful Monte Carlo refits: %.1f %%\n", ...
            100 * mcResult.successfulFraction)
    end
end

%% 4. OPTIONAL TENSILE WORKFLOWS
% Enable only the analyses required for the current experiment.
runFitDiagnostics = false;
runReliabilityAwareModelComparison = false;
runSelectedParameterPopulation = true;
runGroupComparison = false;
runGroupParameterInference = false;
runConstitutiveStudyReport = false;

if ~isempty(processedIndices)
    optionalSpecimen = records(processedIndices(1)).specimen;
    optionalDeformation = optionalSpecimen.processed.strain;
    optionalStress = optionalSpecimen.processed.stress;
    optionalContext = config.datasetAnalysis.fitting.context;
else
    optionalDeformation = [];
    optionalStress = [];
    optionalContext = struct();
end

if runFitDiagnostics
    diagnosticModel = "yeoh";
    fitDiagnostics = mechanics.workflow.runFitDiagnostics( ...
        diagnosticModel, optionalDeformation, optionalStress, ...
        optionalContext, mechanics.config.fittingConfig(), ...
        mechanics.config.fitDiagnosticsWorkflowConfig());
    disp(fitDiagnostics.reliability.componentSummary)
    disp(fitDiagnostics.reliability.status)
    mechanics.plotting.plotFitReliability(fitDiagnostics.reliability);
    mechanics.io.exportFitDiagnostics( ...
        fitDiagnostics, fullfile(outputFolder, "fit-diagnostics"));
end

if runReliabilityAwareModelComparison
    modelComparison = mechanics.workflow.compareModelsWithDiagnostics( ...
        config.datasetAnalysis.fitting.modelNames, ...
        optionalDeformation, optionalStress, optionalContext, ...
        mechanics.config.fittingConfig(), ...
        mechanics.config.modelComparisonWorkflowConfig());
    disp(modelComparison.summary)
    disp(modelComparison.selectedModelName)
    mechanics.plotting.plotModelComparison(modelComparison);
    mechanics.io.exportModelComparison( ...
        modelComparison, fullfile(outputFolder, "model-comparison"));
end

if runSelectedParameterPopulation || ...
        runGroupParameterInference || runConstitutiveStudyReport
    comparisonSpecimens = struct([]);
    outputIndex = 0;
    for index = processedIndices
        outputIndex = outputIndex + 1;
        processedSpecimen = records(index).specimen;
        comparisonSpecimens(outputIndex).specimenId = ...
            string(processedSpecimen.id); %#ok<SAGROW>
        comparisonSpecimens(outputIndex).group = "Unassigned"; %#ok<SAGROW>
        comparisonSpecimens(outputIndex).deformation = ...
            processedSpecimen.processed.strain; %#ok<SAGROW>
        comparisonSpecimens(outputIndex).measuredStress = ...
            processedSpecimen.processed.stress; %#ok<SAGROW>
        comparisonSpecimens(outputIndex).context = ...
            config.datasetAnalysis.fitting.context; %#ok<SAGROW>
    end

    parameterBatch = mechanics.workflow.compareModelsAcrossSpecimens( ...
        comparisonSpecimens, config.datasetAnalysis.fitting.modelNames, ...
        mechanics.config.fittingConfig(), ...
        mechanics.config.batchModelComparisonConfig());
    parameterPopulation = mechanics.workflow.summarizeSelectedParameters( ...
        parameterBatch, ...
        mechanics.config.selectedParameterPopulationConfig());
    disp(parameterPopulation.parameterTable)
    disp(parameterPopulation.overallSummary)
    disp(parameterPopulation.groupSummary)

    if runSelectedParameterPopulation
        mechanics.io.exportSelectedParameterPopulation( ...
            parameterPopulation, ...
            fullfile(outputFolder, "selected-parameter-population"));
    end
end

if runGroupComparison
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
    mechanics.plotting.plotGroupComparison(groupComparison);
    mechanics.io.exportGroupComparison( ...
        groupComparison, fullfile(outputFolder, "group-comparison"));
end

if runGroupParameterInference
    parameterInference = ...
        mechanics.workflow.compareSelectedParametersBetweenGroups( ...
        parameterPopulation, ...
        mechanics.config.groupParameterInferenceConfig());
    disp(parameterInference.comparisonTable)
    mechanics.plotting.plotGroupParameterInference(parameterInference);
    mechanics.io.exportGroupParameterInference( ...
        parameterInference, ...
        fullfile(outputFolder, "group-parameter-inference"));
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
