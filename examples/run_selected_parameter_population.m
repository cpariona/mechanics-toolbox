%RUN_SELECTED_PARAMETER_POPULATION Summarize selected parameters across specimens.
startup;
strain = linspace(0,0.5,51)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
parameters = [12,14,17,19];
groups = ["Control","Control","Treatment","Treatment"];
for index = 1:numel(parameters)
    specimens(index).specimenId = "Specimen-" + index; %#ok<SAGROW>
    specimens(index).group = groups(index); %#ok<SAGROW>
    specimens(index).deformation = strain; %#ok<SAGROW>
    specimens(index).measuredStress = mechanics.models.evaluateModel( ...
        "neo-hookean", strain, parameters(index), context); %#ok<SAGROW>
    specimens(index).context = context; %#ok<SAGROW>
end
batchConfig = mechanics.config.batchModelComparisonConfig();
workflow = batchConfig.comparisonConfig.fitDiagnosticsConfig;
workflow.runBootstrap = false;
workflow.runIdentifiability = false;
workflow.runWindowStability = false;
workflow.runResidualDiagnostics = false;
batchConfig.comparisonConfig.fitDiagnosticsConfig = workflow;
batch = mechanics.workflow.compareModelsAcrossSpecimens( ...
    specimens, "neo-hookean", mechanics.config.fittingConfig(), batchConfig);
population = mechanics.workflow.summarizeSelectedParameters(batch);
disp(population.parameterTable)
disp(population.overallSummary)
disp(population.groupSummary)
mechanics.plotting.plotSelectedParameterPopulation(population);
mechanics.io.exportSelectedParameterPopulation( ...
    population, "results/selected-parameter-population");
