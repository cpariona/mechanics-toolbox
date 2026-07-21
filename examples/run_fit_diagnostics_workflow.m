%RUN_FIT_DIAGNOSTICS_WORKFLOW Demonstrate the complete diagnostic pipeline.
startup;

strain = linspace(0, 0.6, 61)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";

stress = mechanics.models.evaluateModel( ...
    "neo-hookean", strain, 15, context);
measuredStress = stress + 0.10 .* sin((1:numel(strain))');

fitConfig = mechanics.config.fittingConfig();
workflowConfig = mechanics.config.fitDiagnosticsWorkflowConfig();
workflowConfig.bootstrapConfig.sampleCount = 40;

analysis = mechanics.workflow.runFitDiagnostics( ...
    "neo-hookean", strain, measuredStress, context, ...
    fitConfig, workflowConfig);

disp(analysis.reliability.componentSummary)
disp(analysis.reliability.status)

mechanics.plotting.plotFitReliability(analysis.reliability);
mechanics.io.exportFitDiagnostics( ...
    analysis, "results/fit-diagnostics");