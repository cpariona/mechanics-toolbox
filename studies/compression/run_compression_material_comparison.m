%% 0. INITIALIZATION AND COMPLETED STUDIES
% Compare completed ASTM D575 compression studies for Ecoflex 00-20 and 00-50.
% This driver consumes completed study MAT files and does not re-import or
% reprocess the raw workbooks.

restoredefaultpath
clear classes
clear functions
clear
clc
close all

repositoryFolder = 'D:\Escritorio\mechanics-toolbox';
cd(repositoryFolder)
startup

studyFile0020 = fullfile( ...
    repositoryFolder, "results", ...
    "real-compression-study-ecoflex0020", ...
    "compression_study.mat");
studyFile0050 = fullfile( ...
    repositoryFolder, "results", ...
    "real-compression-study", ...
    "compression_study.mat");
outputFolder = fullfile( ...
    repositoryFolder, "results", ...
    "compression-ecoflex0020-vs-0050");

groupLabels = [
    "Ecoflex 00-20"
    "Ecoflex 00-50"
];

%% 1. LOAD COMPLETED STUDIES
if ~isfile(studyFile0020)
    error("mechanics:studies:MissingEcoflex0020CompressionStudy", ...
        ["Ecoflex 00-20 completed compression study not found: %s\n" ...
         "Run the maintained compression study workflow for " ...
         "Compression_ASTM_D575_ECOFLEX0020_test.xlsx and export it to " ...
         "results/real-compression-study-ecoflex0020 first."], ...
        studyFile0020);
end
if ~isfile(studyFile0050)
    error("mechanics:studies:MissingEcoflex0050CompressionStudy", ...
        ["Ecoflex 00-50 completed compression study not found: %s\n" ...
         "Run studies/compression/run_compression_experiment.m first."], ...
        studyFile0050);
end

loaded0020 = load(studyFile0020, "study");
loaded0050 = load(studyFile0050, "study");
if ~isfield(loaded0020, "study") || ~isfield(loaded0050, "study")
    error("mechanics:studies:InvalidCompressionStudyBundle", ...
        "Each completed compression-study MAT file must contain variable 'study'.");
end

studies = [loaded0020.study; loaded0050.study];

%% 2. COMPARISON CONFIGURATION
config = mechanics.config.compressionStudyComparisonConfig();
config.requireMatchingMeasures = true;
config.requireMatchingUnits = true;

comparisonConfig = config.groupComparison;
comparisonConfig.minimumSpecimensPerGroup = 2;
comparisonConfig.bootstrap.enabled = true;
comparisonConfig.bootstrap.iterations = 2000;
comparisonConfig.bootstrap.confidenceLevel = 0.95;
comparisonConfig.bootstrap.randomSeed = 11;
comparisonConfig.export.enabled = true;
comparisonConfig.export.outputFolder = outputFolder;
config.groupComparison = comparisonConfig;

%% 3. RUN COMPLETED-STUDY COMPARISON
tic
comparison = mechanics.workflow.compareCompressionStudies( ...
    studies, groupLabels, config);
elapsedTime = toc;

fprintf("Compression material comparison completed in %.2f seconds.\n", ...
    elapsedTime)
disp(comparison.studySummaries)
disp(comparison.compatibility)

if isfield(comparison.groupComparison, "metricComparison")
    disp(comparison.groupComparison.metricComparison)
end

if isfield(comparison.groupComparison, "outputFiles")
    disp(comparison.groupComparison.outputFiles)
end

%% 4. INTERACTIVE REVIEW
% Persistent comparison figures are owned by exportGroupComparison.
if isfield(comparison.groupComparison, "curveComparison") && ...
        ~isempty(fieldnames(comparison.groupComparison.curveComparison))
    mechanics.plotting.plotGroupComparison(comparison.groupComparison);
end
