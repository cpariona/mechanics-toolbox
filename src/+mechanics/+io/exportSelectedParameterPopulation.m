function files = exportSelectedParameterPopulation(population, outputFolder)
%EXPORTSELECTEDPARAMETERPOPULATION Export selected-model parameter summaries.
arguments
    population (1,1) struct
    outputFolder (1,1) string
end
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
parameterFile = fullfile(outputFolder,'selected_parameters.csv');
overallFile = fullfile(outputFolder,'selected_parameter_overall_summary.csv');
groupFile = fullfile(outputFolder,'selected_parameter_group_summary.csv');
errorFile = fullfile(outputFolder,'selected_parameter_extraction_errors.csv');
initialShearFile = fullfile(outputFolder,'initial_shear_modulus_values.csv');
initialShearSummaryFile = fullfile(outputFolder,'initial_shear_modulus_summary.csv');
initialShearErrorFile = fullfile(outputFolder,'initial_shear_modulus_errors.csv');
dataFile = fullfile(outputFolder,'selected_parameter_population.mat');
writetable(population.parameterTable, parameterFile);
writetable(population.overallSummary, overallFile);
writetable(population.groupSummary, groupFile);
writetable(population.extractionErrors, errorFile);
if isfield(population,'initialShearModulus')
    writetable(population.initialShearModulus.values, initialShearFile);
    writetable(population.initialShearModulus.summary, initialShearSummaryFile);
    writetable(population.initialShearModulus.errors, initialShearErrorFile);
else
    writetable(table(), initialShearFile);
    writetable(table(), initialShearSummaryFile);
    writetable(table(), initialShearErrorFile);
end
save(dataFile,'population');
files.parameters = string(parameterFile);
files.overall = string(overallFile);
files.groups = string(groupFile);
files.errors = string(errorFile);
files.initialShearValues = string(initialShearFile);
files.initialShearSummary = string(initialShearSummaryFile);
files.initialShearErrors = string(initialShearErrorFile);
files.data = string(dataFile);
end
