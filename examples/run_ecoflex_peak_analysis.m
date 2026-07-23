%RUN_ECOFLEX_PEAK_ANALYSIS Compute peak and post-peak metrics for Ecoflex.
startup;

run_ecoflex_segmented_analysis

peakConfig = mechanics.config.fractureAnalysisConfig();
peakConfig.integrateAbsoluteDisplacement = false;
peakConfig.minimumObservations = 3;

analysis = mechanics.workflow.addFractureMetrics( ...
    analysis, peakConfig);

disp(analysis.fractureSummary);

mechanics.plotting.plotFractureMetrics( ...
    analysis.fractureSummary);

files = mechanics.io.exportFractureAnalysis( ...
    analysis, "results/ecoflex-0050/peak-analysis");

disp(files);
