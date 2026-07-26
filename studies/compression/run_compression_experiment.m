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

config = mechanics.config.compressionStudyConfig();

% Workbook extraction. The shared Zwick adapter reads specimen sheets and
% obtains circular compression geometry from d0 and h0 in Resultados.
config.input.type = "workbook";
config.extraction.extractor = "auto";

% ASTM D575 Method A uses three cycles. The first two condition the specimen;
% the third loading branch provides the maintained measurement response.
config.specimen.cycle.selection = "last-complete-cycle";
config.specimen.cycle.branch = "loading";
config.specimen.cycle.loadingDirection = "increasing";
config.specimen.cycle.minimumObservations = 5;
config.specimen.cycle.smoothingFrameLength = 5;

% The selected branch begins at its first observation. No preload threshold
% is used for the maintained Method A workflow.
config.specimen.processing.preprocessing.zeroReference.method = ...
    "first-sample";
config.specimen.processing.preprocessing.zeroReference.trimBeforeReference = ...
    true;

% Engineering strain and nominal stress are retained as physical signed
% compression quantities. Report plots below use positive magnitudes only.
config.specimen.processing.mechanics.strainMeasure = "engineering";
config.specimen.processing.mechanics.stressMeasure = "engineering";
config.specimen.processing.analysis.summaryStrainRange = [-0.40, 0.00];

% Specimen exclusions are explicit and follow workbook extraction order.
% These two specimens are outside the ASTM D575 thickness tolerance for the
% current experiment. Update this section for each new workbook.
config.specimens.excludeIndices = [1; 2];
config.specimens.exclusionReason = ...
    "Initial thickness outside ASTM D575 tolerance";

% Constitutive fitting can be enabled after the maintained cycle and fitting
% range have been reviewed for the experiment.
config.specimen.fitting.enabled = false;
config.specimen.export.enabled = false;

% Population analysis uses only records with status "processed".
config.population.enabled = true;
config.population.continueOnError = true;
config.population.config.minimumSpecimens = 2;
config.population.config.strainGridPointCount = 201;
config.population.config.bootstrap.enabled = true;
config.population.config.bootstrap.iterations = 2000;
config.population.config.bootstrap.confidenceLevel = 0.95;
config.population.config.bootstrap.randomSeed = 1;

%% 2. RUN THE COMPLETE COMPRESSION WORKFLOW

tic
study = mechanics.workflow.runCompressionStudy(inputFile, config);
elapsedTime = toc;

fprintf('Study completed in %.2f seconds.\n', elapsedTime)
disp(study.exclusion)
disp(study.manifest)
disp(study.analysis.summary)
fprintf('Population status: %s\n', char(study.populationStatus))

if study.populationStatus == "failed"
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

%% 4. PLOTS

records = study.analysis.records;
processedMask = string({records.status}) == "processed";
processedIndices = find(processedMask);

figure("Color", "w")
hold on
for index = processedIndices(:)'
    record = records(index);
    processed = record.specimen.processed;
    plot( ...
        -processed.strain, ...
        -processed.stress, ...
        "LineWidth", 1.3, ...
        "DisplayName", record.specimenId);
end
xlabel("Compression engineering strain magnitude")
ylabel("Compression nominal stress magnitude")
title("ASTM D575 Method A compression study")
legend("Location", "best")
grid on
box on
hold off

exportgraphics(gcf, ...
    fullfile(outputFolder, "compression_stress_strain.png"), ...
    "Resolution", 300);

% Inspect the selected full cycle and processed loading branch for the first
% retained specimen.
if ~isempty(processedIndices)
    record = records(processedIndices(1));
    specimen = record.specimen;

    figure("Color", "w")
    tiledlayout(1, 2, "TileSpacing", "compact", "Padding", "compact")

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
        "LineWidth", 1.3)
    xlabel("Compression strain magnitude")
    ylabel("Compression stress magnitude")
    title("Processed loading branch")
    grid on
    box on

    exportgraphics(gcf, ...
        fullfile(outputFolder, "compression_cycle_check.png"), ...
        "Resolution", 300);
end
