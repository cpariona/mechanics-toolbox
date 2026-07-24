%RUN_ECOFLEX_PEAK_ANALYSIS Compute peak and post-peak metrics for Ecoflex.
startup;

run_ecoflex_segmented_analysis

peakConfig = mechanics.config.peakAnalysisConfig();
peakConfig.integrateAbsoluteDisplacement = false;
peakConfig.minimumObservations = 3;

analysis = mechanics.workflow.addPeakMetrics(analysis, peakConfig);

disp(analysis.peakSummary);

mechanics.plotting.plotPeakMetrics(analysis.peakSummary);

files = mechanics.io.exportPeakAnalysis( ...
    analysis, "results/ecoflex-0050/peak-analysis");

disp(files);
