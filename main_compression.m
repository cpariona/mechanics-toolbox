clc; clear; close all;

warning('off', 'all')

% ---------------- CONFIGURATION ---------------- %

rootDir = 'D:\CompressionTest_EF0020-EF0050_test\';
rawDataDir = fullfile(rootDir, 'RawData');
saveFolder = fullfile(rootDir, 'Summary Figures', 'Compression');
processedFolder = fullfile(rootDir, 'Processed Data');

files = {
    fullfile(rawDataDir, 'Compression_ASTM_D575_ECOFLEX0020_test.xlsx'), ...
    fullfile(rawDataDir, 'Compression_ASTM_D575_ECOFLEX0050_test.xlsx')};

ratios = {
    'Ecoflex 00-20', ...
    'Ecoflex 00-50'};

specimens_list = {
    {'Probeta 10','Probeta 11','Probeta 12','Probeta 13'}, ...
    {'Probeta 6','Probeta 7','Probeta 8','Probeta 9'}};

settings = defaultCompressionSettings();

settings.zero_displacement_at_start = false;
settings.zero_force_at_start = false;

settings.window_mode = "auto";
settings.manual_start_idx = 1800;
settings.manual_end_idx = 2600;
settings.zero_window_start = true;
settings.end_trim_samples = 10;

settings.i_samples = 20;
settings.E_window_samples = 100;

settings.smooth_stress_strain = true;
settings.smooth_frame_length = 21;
settings.smooth_poly_order = 3;

settings.smooth_E_t_for_plot = true;
settings.E_t_plot_smooth_frame_length = 51;

% ---------------- PROCESS, SAVE, AND PLOT ---------------- %

experiment = processCompressionExperiment(files, ratios, specimens_list, settings);

saveProcessedExperiment(experiment, processedFolder, 'compression_processed_data');

plotMechanicalSpecimenCurves(experiment, saveFolder);
plotMechanicalMedianStressCurves(experiment, saveFolder);
plotMechanicalMedianModulusCurves(experiment, saveFolder);
plotMechanicalCombinedStressCurves(experiment, saveFolder);
