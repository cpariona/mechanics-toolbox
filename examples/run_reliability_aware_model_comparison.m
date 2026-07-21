%RUN_RELIABILITY_AWARE_MODEL_COMPARISON Compare candidate constitutive models.
startup;

strain = linspace(0, 0.6, 61)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

stress = mechanics.models.evaluateModel( ...
    "neo-hookean", strain, 15, context);
measuredStress = stress + 0.03 .* sin((1:numel(strain))');

fitConfig = mechanics.config.fittingConfig();
config = mechanics.config.modelComparisonWorkflowConfig();
config.fitDiagnosticsConfig.bootstrapConfig.sampleCount = 30;

comparison = mechanics.workflow.compareModelsWithDiagnostics( ...
    ["neo-hookean", "mooney-rivlin", "yeoh"], ...
    strain, measuredStress, context, fitConfig, config);

disp(comparison.summary)
disp(comparison.selectedModelName)
mechanics.plotting.plotModelComparison(comparison);
mechanics.io.exportModelComparison( ...
    comparison, "results/model-comparison");
