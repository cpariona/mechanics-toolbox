%RUN_CONSTITUTIVE_STUDY_REPORT Build and export an integrated study report.
startup;
strain = linspace(0, 0.5, 51)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
parameters = [12 13 14 20 21 22];
groups = ["Control" "Control" "Control" "Treatment" "Treatment" "Treatment"];
for index = 1:numel(parameters)
    specimens(index).specimenId = "S" + index; %#ok<SAGROW>
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
    specimens, ["neo-hookean" "mooney-rivlin"], ...
    mechanics.config.fittingConfig(), batchConfig);
population = mechanics.workflow.summarizeSelectedParameters(batch);
inferenceConfig = mechanics.config.groupParameterInferenceConfig();
inferenceConfig.permutationCount = 500;
inferenceConfig.bootstrapCount = 500;
inference = mechanics.workflow.compareSelectedParametersBetweenGroups( ...
    population, inferenceConfig);

reportConfig = mechanics.config.constitutiveStudyReportConfig();
reportConfig.outputFolder = "results/constitutive-study-report";
files = mechanics.io.exportConstitutiveStudyReport( ...
    batch, population, inference, reportConfig);
disp(files)
