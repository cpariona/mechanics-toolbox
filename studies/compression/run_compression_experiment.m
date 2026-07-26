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
    repositoryFolder, ...
    "data", ...
    "raw", ...
    "Compression_ASTM_D575_ECOFLEX0050_test.xlsx");

outputFolder = fullfile( ...
    repositoryFolder, ...
    "results", ...
    "real-compression-study");

%% 1. STUDY CONFIGURATION
% This section contains the settings normally modified between studies.

config = mechanics.config.compressionStudyConfig();

% Workbook extraction.
% extractor:
%   "auto"    : detects the workbook format automatically.
%   registered extractor name: forces a specific supported format.
% The shared Zwick adapter obtains circular compression geometry from d0 and
% h0 in the Resultados sheet.
config.input.type = "workbook";
config.extraction.extractor = "auto";

% ASTM D575 Method A uses three cycles. The first two condition the specimen;
% the third loading branch provides the maintained measurement response.
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

% Stress and strain measures. Stored compression quantities retain physical
% negative signs. Presentation plots below use positive magnitudes.
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

% Specimen exclusions are explicit and follow workbook extraction order.
% Update this section for each new workbook.
config.specimens.excludeIndices = [1; 2];
config.specimens.exclusionReason = ...
    "Initial thickness outside ASTM D575 tolerance";

% Constitutive fitting and model selection. The maintained constitutive
% functions accept physical compression strain and stress directly.
fitting = config.specimen.fitting;
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
fitting.selectionConfig.windowFractions = [0.50, 0.75, 1.00];
fitting.selectionConfig.minimumObservations = 20;
fitting.selectionConfig.rankingMetric = "BIC";
fitting.selectionConfig.requireConvergence = true;
fitting.selectionConfig.maximumRelativeParameterCV = 0.50;

% Measurement Monte Carlo for fitted parameters. Keep disabled until
% supported standard uncertainties are available.
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

% Pointwise propagation of geometry uncertainty. Keep disabled until h0 and
% A0 standard uncertainties are available.
geometryUncertainty = config.specimen.processing.uncertainty.geometry;
geometryUncertainty.enabled = false;
geometryUncertainty.initialLengthStd = NaN; % mm
geometryUncertainty.initialAreaStd = NaN;   % mm^2
config.specimen.processing.uncertainty.geometry = geometryUncertainty;

% Individual specimen export remains disabled because this driver writes one
% integrated study folder below.
config.specimen.export.enabled = false;

% Population analysis uses only records with status "processed".
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

%% 2. RUN THE COMPLETE COMPRESSION WORKFLOW
% Extraction, cycle selection, physical-sign normalization, mechanical
% processing, tangent modulus, fitting, and population analysis run here.

tic
study = mechanics.workflow.runCompressionStudy(inputFile, config);
elapsedTime = toc;

fprintf('Study completed in %.2f seconds.\n', elapsedTime)
disp(study.exclusion)
disp(study.manifest)
disp(study.analysis.summary)
fprintf('Population status: %s\n', char(study.populationStatus))

if study.populationStatus == "completed"
    disp(study.population.metrics)
    disp(study.population.modelParameters)
elseif study.populationStatus == "failed"
    fprintf(2, 'Population error: %s\n', ...
        char(study.populationErrorMessage))
end

%% 3. SAVE MAINTAINED RESULTS

if ~isfolder(outputFolder)
    mkdir(outputFolder)
end

save(fullfile(outputFolder, "compression_study.mat"), ...
    "study", "config");

writetable(study.manifest, ...
    fullfile(outputFolder, "compression_manifest.csv"));
writetable(study.analysis.summary, ...
    fullfile(outputFolder, "compression_summary.csv"));

if study.populationStatus == "completed"
    populationFiles = mechanics.io.exportPopulationAnalysis( ...
        study.population, outputFolder);
    disp(populationFiles)
end

%% 4. RESULTS AND PLOTS

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
processedMask = string({records.status}) == "processed";
processedIndices = find(processedMask);

% Inspect the first processed specimen using the same hierarchy as tension:
% raw/cycle data, processed response, tangent modulus, selected model, and
% optional Monte Carlo output.
if ~isempty(processedIndices)
    specimenIndex = processedIndices(1);
    record = records(specimenIndex);
    specimen = record.specimen;

    mechanics.plotting.plotStressStrain( ...
        specimen.processed, ...
        Title="Processed compression specimen: " + string(specimen.id), ...
        DisplayName="Experimental");

    figure("Color", "w")
    tiledlayout(1, 3, "TileSpacing", "compact", "Padding", "compact")

    nexttile
    plot( ...
        specimen.originalRaw.displacement, ...
        specimen.originalRaw.force, ...
        "LineWidth", 1.0)
    xlabel("Instrument displacement")
    ylabel("Instrument force")
    title("Original recorded cycles")
    grid on
    box on

    nexttile
    plot( ...
        specimen.fullCycleRaw.displacement, ...
        specimen.fullCycleRaw.force, ...
        "LineWidth", 1.1)
    xlabel("Compression displacement magnitude")
    ylabel("Compression force magnitude")
    title("Selected third cycle")
    grid on
    box on

    nexttile
    plot( ...
        -specimen.processed.strain, ...
        -specimen.processed.stress, ...
        "LineWidth", 1.4)
    xlabel("Compression strain magnitude")
    ylabel("Compression nominal stress magnitude")
    title("Processed loading branch")
    grid on
    box on

    exportgraphics(gcf, ...
        fullfile(outputFolder, "compression_cycle_check.png"), ...
        "Resolution", 300);

    tangent = specimen.analysis.tangentModulus;
    figure("Color", "w")
    plot( ...
        -tangent.strain, ...
        tangent.tangentModulusForPlot, ...
        "LineWidth", 1.4)
    xlabel("Compression engineering strain magnitude")
    ylabel("Tangent modulus")
    title("Compression tangent modulus")
    grid on
    box on
    exportgraphics(gcf, ...
        fullfile(outputFolder, "compression_tangent_modulus.png"), ...
        "Resolution", 300);

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
            'VariableNames', { ...
                'Parameter', 'BaseEstimate', 'Lower', 'Median', 'Upper'});
        disp(mcTable)
        fprintf('Successful Monte Carlo refits: %.1f %%\n', ...
            100 * mcResult.successfulFraction)
    end
end

% Plot all retained specimen curves.
figure("Color", "w")
hold on
for index = processedIndices(:)'
    record = records(index);
    processed = record.specimen.processed;
    plot( ...
        -processed.strain, ...
        -processed.stress, ...
        "LineWidth", 1.2, ...
        "DisplayName", record.specimenId);
end
xlabel("Compression engineering strain magnitude")
ylabel("Compression nominal stress magnitude")
title("Retained ASTM D575 Method A specimens")
legend("Location", "best")
grid on
box on
hold off
exportgraphics(gcf, ...
    fullfile(outputFolder, "compression_stress_strain.png"), ...
    "Resolution", 300);

% Population stress-strain response with individual curves, bootstrap interval,
% and central response.
if study.populationStatus == "completed"
    aggregate = study.population.curves;
    figure("Color", "w")
    hold on

    for index = 1:size(aggregate.stressMatrix, 2)
        plot( ...
            -aggregate.strain, ...
            -aggregate.stressMatrix(:, index), ...
            "LineWidth", 0.8, ...
            "HandleVisibility", "off")
    end

    finiteInterval = ...
        all(isfinite(aggregate.confidenceLower)) && ...
        all(isfinite(aggregate.confidenceUpper));
    if finiteInterval
        fill( ...
            [-aggregate.strain; flipud(-aggregate.strain)], ...
            [-aggregate.confidenceLower; ...
             flipud(-aggregate.confidenceUpper)], ...
            0.8 .* [1, 1, 1], ...
            "EdgeColor", "none", ...
            "FaceAlpha", 0.5, ...
            "DisplayName", sprintf('%.0f%% bootstrap CI', ...
                100 * aggregate.config.bootstrap.confidenceLevel))
    end

    centralStatistic = string(aggregate.config.centralStatistic);
    if centralStatistic == "median" && isfield(aggregate, "medianStress")
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
        -aggregate.strain, ...
        -centralCurve, ...
        "LineWidth", 2, ...
        "DisplayName", char(centralLabel))
    xlabel("Compression engineering strain magnitude")
    ylabel("Compression nominal stress magnitude")
    title("Population compression response")
    legend("Location", "best")
    grid on
    box on
    hold off
    exportgraphics(gcf, ...
        fullfile(outputFolder, "compression_population.png"), ...
        "Resolution", 300);

    if study.population.tangentModulusStatus == "completed"
        tangentPopulation = study.population.tangentModulus;
        figure("Color", "w")
        hold on
        for index = 1:size(tangentPopulation.modulusMatrix, 2)
            plot( ...
                -tangentPopulation.strain, ...
                tangentPopulation.modulusMatrix(:, index), ...
                "LineWidth", 0.8, ...
                "HandleVisibility", "off")
        end

        if all(isfinite(tangentPopulation.confidenceLower)) && ...
                all(isfinite(tangentPopulation.confidenceUpper))
            fill( ...
                [-tangentPopulation.strain; ...
                 flipud(-tangentPopulation.strain)], ...
                [tangentPopulation.confidenceLower; ...
                 flipud(tangentPopulation.confidenceUpper)], ...
                0.8 .* [1, 1, 1], ...
                "EdgeColor", "none", ...
                "FaceAlpha", 0.5, ...
                "DisplayName", sprintf('%.0f%% bootstrap CI', ...
                    100 * tangentPopulation.config.bootstrap.confidenceLevel))
        end

        plot( ...
            -tangentPopulation.strain, ...
            tangentPopulation.centralModulus, ...
            "LineWidth", 2, ...
            "DisplayName", char(tangentPopulation.config.centralStatistic))
        xlabel("Compression engineering strain magnitude")
        ylabel("Tangent modulus")
        title("Population compression tangent modulus")
        legend("Location", "best")
        grid on
        box on
        hold off
        exportgraphics(gcf, ...
            fullfile(outputFolder, "compression_population_tangent_modulus.png"), ...
            "Resolution", 300);
    end
end

%% 5. OPTIONAL COMPRESSION WORKFLOWS
% These downstream constitutive workflows are shared with tension and apply to
% compression because the model context and physical sign contract are common.

runFitDiagnostics = false;
runReliabilityAwareModelComparison = false;
runSelectedParameterPopulation = true;
runGroupComparison = false;
runGroupParameterInference = false;
runConstitutiveStudyReport = false;

% Use the first processed specimen as the default optional-analysis target.
if ~isempty(processedIndices)
    optionalRecord = records(processedIndices(1));
    optionalSpecimen = optionalRecord.specimen;
    optionalDeformation = optionalSpecimen.processed.strain;
    optionalStress = optionalSpecimen.processed.stress;
    optionalContext = config.specimen.fitting.context;
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
        config.specimen.fitting.modelNames, ...
        optionalDeformation, optionalStress, optionalContext, ...
        mechanics.config.fittingConfig(), comparisonConfig);
    disp(modelComparison.summary)
    disp(modelComparison.selectedModelName)
    mechanics.plotting.plotModelComparison(modelComparison);
    mechanics.io.exportModelComparison( ...
        modelComparison, fullfile(outputFolder, "model-comparison"));
end

% Batch comparison and population summary of selected-model parameters.
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
            config.specimen.fitting.context; %#ok<SAGROW>
    end

    batchConfig = mechanics.config.batchModelComparisonConfig();
    parameterBatch = mechanics.workflow.compareModelsAcrossSpecimens( ...
        comparisonSpecimens, ...
        config.specimen.fitting.modelNames, ...
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

% Descriptive comparison of user-defined groups inside this study.
if runGroupComparison
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

% Comparisons between completed compression studies are intentionally separate
% from this single-study driver:
% comparison = mechanics.workflow.compareCompressionStudies(...)
