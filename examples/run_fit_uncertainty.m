%RUN_FIT_UNCERTAINTY Demonstrate bootstrap uncertainty for one fitted model.
startup;

strain = linspace(0, 0.6, 61)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

trueStress = mechanics.models.evaluateModel( ...
    "neo-hookean", strain, 15, context);
measuredStress = trueStress + 0.15 .* sin((1:numel(strain))');

fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 4;
fitResult = mechanics.fitting.fitModel( ...
    "neo-hookean", strain, measuredStress, context, fitConfig);

uncertaintyConfig = mechanics.config.fitUncertaintyConfig();
uncertaintyConfig.sampleCount = 200;
uncertaintyConfig.confidenceLevel = 0.95;

uncertainty = mechanics.fitting.bootstrapFitUncertainty( ...
    fitResult, uncertaintyConfig);

mechanics.plotting.plotFitUncertainty(fitResult, uncertainty);

files = mechanics.io.exportFitUncertainty( ...
    fitResult, uncertainty, "results/fit-uncertainty");

disp(table( ...
    uncertainty.parameterNames(:), ...
    uncertainty.baseParameters(:), ...
    uncertainty.parameterLower(:), ...
    uncertainty.parameterUpper(:), ...
    'VariableNames', { ...
        'Parameter', 'BestFit', 'Lower', 'Upper'}));

disp(files);
