%RUN_FIT_RELIABILITY Demonstrate integrated constitutive-fit assessment.
startup;

strain = linspace(0, 0.6, 61)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

stress = mechanics.models.evaluateModel( ...
    "neo-hookean", strain, 15, context);
measuredStress = stress + 0.10 .* sin((1:numel(strain))');

fitResult = mechanics.fitting.fitModel( ...
    "neo-hookean", strain, measuredStress, context);

uncertaintyConfig = mechanics.config.fitUncertaintyConfig();
uncertaintyConfig.sampleCount = 40;
uncertainty = mechanics.fitting.bootstrapFitUncertainty( ...
    fitResult, uncertaintyConfig);

identifiability = mechanics.fitting.analyzeFitIdentifiability( ...
    fitResult, uncertainty);
windowStability = mechanics.fitting.analyzeFitWindowStability( ...
    "neo-hookean", strain, measuredStress, context);
residualDiagnostics = mechanics.fitting.analyzeFitResiduals(fitResult);

assessment = mechanics.fitting.assessFitReliability( ...
    fitResult, uncertainty, identifiability, ...
    windowStability, residualDiagnostics);

disp(assessment.componentSummary)
disp(assessment.status)
mechanics.plotting.plotFitReliability(assessment);
mechanics.io.exportFitReliability( ...
    assessment, "results/fit-reliability");
