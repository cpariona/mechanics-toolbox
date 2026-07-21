%RUN_FIT_WINDOW_STABILITY Demonstrate parameter stability across windows.
startup;

strain = linspace(0, 0.8, 81)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

stress = mechanics.models.evaluateModel( ...
    "mooney-rivlin", strain, [8, 4], context);
stress = stress + 0.03 .* sin((1:numel(strain))');

fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 4;

config = mechanics.config.fitWindowStabilityConfig();
config.windowFractions = [0.30, 0.45, 0.60, 0.75, 0.90, 1.00];

stability = mechanics.fitting.analyzeFitWindowStability( ...
    "mooney-rivlin", strain, stress, context, fitConfig, config);

mechanics.plotting.plotFitWindowStability(stability);
files = mechanics.io.exportFitWindowStability( ...
    stability, "results/fit-window-stability");

disp(stability.windowSummary);
disp(stability.parameterSummary);
disp(files);
