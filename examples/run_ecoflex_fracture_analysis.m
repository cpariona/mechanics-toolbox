%RUN_ECOFLEX_FRACTURE_ANALYSIS Compute fracture metrics for Ecoflex.
startup;

run_ecoflex_segmented_analysis

fractureConfig = mechanics.config.fractureAnalysisConfig();
fractureConfig.completeFractureDropFraction = 0.90;
fractureConfig.residualForceFraction = 0.10;

analysis = mechanics.workflow.addFractureMetrics( ...
    analysis, fractureConfig);

disp(analysis.fractureSummary);

mechanics.plotting.plotFractureMetrics( ...
    analysis.fractureSummary);

files = mechanics.io.exportFractureAnalysis( ...
    analysis, "results/ecoflex-0050/fracture");

disp(files);
