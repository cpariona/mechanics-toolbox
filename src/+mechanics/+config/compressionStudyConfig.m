function config = compressionStudyConfig()
%COMPRESSIONSTUDYCONFIG Default single-specimen compression-study configuration.
config.import = mechanics.config.excelImportConfig();
config.geometry.initialLength = NaN;
config.geometry.initialArea = NaN;
config.processing = mechanics.config.compressionConfig();

config.cycle.enabled = true;
config.cycle.selection = "last-complete-cycle";
config.cycle.branch = "loading";
config.cycle.loadingDirection = "increasing";
config.cycle.minimumCycleAmplitude = 0;
config.cycle.minimumObservations = 5;
config.cycle.smoothingFrameLength = 5;

config.export.enabled = false;
config.export.outputFolder = "results/compression-study";
end