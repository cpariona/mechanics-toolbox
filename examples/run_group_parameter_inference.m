%RUN_GROUP_PARAMETER_INFERENCE Compare selected parameters between groups.
startup;

valuesA = [11.8; 12.4; 13.1; 12.7; 11.9];
valuesB = [15.6; 16.2; 15.1; 16.8; 15.9];
values = [valuesA; valuesB];
groups = [repmat("Control",numel(valuesA),1); ...
    repmat("Treatment",numel(valuesB),1)];
count = numel(values);

population.parameterTable = table( ...
    "Specimen-" + (1:count)', groups, ...
    repmat("neo-hookean",count,1), repmat("mu",count,1), values, ...
    nan(count,1), nan(count,1), nan(count,1), ...
    'VariableNames', {'SpecimenId','Group','ModelName','Parameter', ...
    'Value','BootstrapLower','BootstrapMedian','BootstrapUpper'});

config = mechanics.config.groupParameterInferenceConfig();
config.permutationCount = 1000;
config.bootstrapCount = 1000;
inference = mechanics.workflow.compareSelectedParametersBetweenGroups( ...
    population, config);

disp(inference.comparisonTable)
mechanics.plotting.plotGroupParameterInference(inference);
mechanics.io.exportGroupParameterInference( ...
    inference, "results/group-parameter-inference");
