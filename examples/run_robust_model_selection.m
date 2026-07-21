%RUN_ROBUST_MODEL_SELECTION Demonstrate window-based model stability.
startup;

rng(4, "twister");

strain = linspace(0, 1.0, 180)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

trueParameters = [0.08, 0.025];
cleanStress = mechanics.models.evaluateModel( ...
    "mooney-rivlin", strain, trueParameters, context);
measuredStress = cleanStress + 0.0025 .* randn(size(cleanStress));

fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 10;
fitConfig.randomSeed = 2;

selectionConfig = mechanics.config.modelSelectionConfig();
selectionConfig.windowFractions = [0.40, 0.60, 0.80, 1.00];
selectionConfig.minimumObservations = 20;
selectionConfig.maximumRelativeParameterCV = 0.40;
selectionConfig.rankingMetric = "BIC";

study = mechanics.fitting.fitAcrossWindows( ...
    ["neo-hookean", "mooney-rivlin", "yeoh"], ...
    strain, measuredStress, context, fitConfig, selectionConfig);

disp(study.summary(:, { ...
    'Model', ...
    'FullWindowRMSE', ...
    'FullWindowRSquared', ...
    'FullWindowBIC', ...
    'MaximumRelativeParameterCV', ...
    'ParameterStable', ...
    'Eligible'}));

disp(study.selection);

mechanics.plotting.plotWindowStability(study);
