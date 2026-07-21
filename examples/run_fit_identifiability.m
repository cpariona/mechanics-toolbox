%RUN_FIT_IDENTIFIABILITY Diagnose bootstrap parameter identifiability.
startup;

strain = linspace(0, 0.8, 81)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

trueParameters = [8, 4];
trueStress = mechanics.models.evaluateModel( ...
    "mooney-rivlin", strain, trueParameters, context);
measuredStress = trueStress + 0.08 .* sin((1:numel(strain))');

fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 4;
fitResult = mechanics.fitting.fitModel( ...
    "mooney-rivlin", strain, measuredStress, context, fitConfig);

uncertaintyConfig = mechanics.config.fitUncertaintyConfig();
uncertaintyConfig.sampleCount = 200;
uncertainty = mechanics.fitting.bootstrapFitUncertainty( ...
    fitResult, uncertaintyConfig);

diagnostics = mechanics.fitting.analyzeFitIdentifiability( ...
    fitResult, uncertainty);

disp(diagnostics.parameterSummary);
disp(diagnostics.highCorrelationPairs);
fprintf("Weakly identified: %d\n", diagnostics.weaklyIdentified);

mechanics.plotting.plotFitIdentifiability(diagnostics);
files = mechanics.io.exportFitIdentifiability( ...
    diagnostics, "results/fit-identifiability");
disp(files);
