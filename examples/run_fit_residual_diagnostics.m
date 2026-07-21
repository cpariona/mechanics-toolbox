%RUN_FIT_RESIDUAL_DIAGNOSTICS Demonstrate constitutive-fit residual checks.
startup;

strain = linspace(0, 0.7, 71)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

trueStress = mechanics.models.evaluateModel( ...
    "yeoh", strain, [12, 3, 0.5], context);
measuredStress = trueStress + ...
    0.08 .* sin(12 .* strain) + 0.03 .* strain;

fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 4;
fitResult = mechanics.fitting.fitModel( ...
    "neo-hookean", strain, measuredStress, context, fitConfig);

diagnostics = mechanics.fitting.analyzeFitResiduals(fitResult);

disp(diagnostics.metricSummary);
disp(struct( ...
    "hasAutocorrelation", diagnostics.hasAutocorrelation, ...
    "hasDeformationTrend", diagnostics.hasDeformationTrend, ...
    "hasHeteroscedasticity", diagnostics.hasHeteroscedasticity, ...
    "hasOutliers", diagnostics.hasOutliers, ...
    "hasSystematicStructure", diagnostics.hasSystematicStructure));

mechanics.plotting.plotFitResidualDiagnostics(diagnostics);

files = mechanics.io.exportFitResidualDiagnostics( ...
    diagnostics, "results/fit-residual-diagnostics");
disp(files);
