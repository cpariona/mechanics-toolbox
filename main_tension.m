clc; clear; close all;

warning('off', 'all')

% ---------------- CONFIGURATION ---------------- %

rootDir = 'E:\TensionTest_EF0050_test\';
rawDataDir = fullfile(rootDir, 'RawData');
saveFolder = fullfile(rootDir, 'Summary Figures', 'Tension');
processedFolder = fullfile(rootDir, 'Processed Data');

files = {
    fullfile(rawDataDir, 'Tension_ASTM_D412_ECOFLEX0050_test.xlsx')};

ratios = {
    'Ecoflex 00-50'};

specimens_list = {
    {'Probeta 22','Probeta 23','Probeta 24','Probeta 25'}};

settings = defaultTensionSettings();
settings.window_mode = "manual";
settings.manual_start_idx = 6;
settings.manual_end_idx = 5170;
settings.calibrated_length = 25;
settings.zero_window_start = true;
settings.end_trim_samples = 10;
settings.i_samples = 150;
settings.E_window_samples = 500;
settings.smooth_stress_strain = true;
settings.smooth_frame_length = 21;
settings.smooth_poly_order = 3;
settings.smooth_E_t_for_plot = true;
settings.E_t_plot_smooth_frame_length = 500;


% ---------------- PROCESS, SAVE, AND PLOT ---------------- %

experiment = processTensionExperiment(files, ratios, specimens_list, settings);

saveProcessedExperiment(experiment, processedFolder, 'tension_processed_data');

plotMechanicalSpecimenCurves(experiment, saveFolder);
plotMechanicalMedianStressCurves(experiment, saveFolder);
plotMechanicalMedianModulusCurves(experiment, saveFolder);
plotMechanicalCombinedStressCurves(experiment, saveFolder);
