%RUN_BATCH_MODEL_COMPARISON Compare candidate models across specimens.
startup;
strain = linspace(0, 0.6, 61)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
parameters = [12, 14, 16, 18];
groups = ["Control", "Control", "Treatment", "Treatment"];
for index = 1:numel(parameters)
    specimens(index).specimenId = "Specimen-" + index; %#ok<SAGROW>
    specimens(index).group = groups(index); %#ok<SAGROW>
    specimens(index).deformation = strain; %#ok<SAGROW>
    trueStress = mechanics.models.evaluateModel( ...
        "neo-hookean", strain, parameters(index), context);
    specimens(index).measuredStress = trueStress + ...
        0.02 .* sin((1:numel(strain))' + index); %#ok<SAGROW>
    specimens(index).context = context; %#ok<SAGROW>
end

config = mechanics.config.batchModelComparisonConfig();
config.comparisonConfig.fitDiagnosticsConfig.bootstrapConfig.sampleCount = 30;

batch = mechanics.workflow.compareModelsAcrossSpecimens( ...
    specimens, ["neo-hookean", "mooney-rivlin", "yeoh"], ...
    mechanics.config.fittingConfig(), config);

disp(batch.specimenSummary)
disp(batch.modelSummary)
disp(batch.groupSummary)
mechanics.plotting.plotBatchModelComparison(batch);
mechanics.io.exportBatchModelComparison( ...
    batch, "results/batch-model-comparison");
