function files = exportSelectedParameterPopulation(population, outputFolder)
%EXPORTSELECTEDPARAMETERPOPULATION Export consensus-model parameter results.
arguments
    population (1,1) struct
    outputFolder (1,1) string
end
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

selectionFile = fullfile(outputFolder,'consensus_model_selection.csv');
parameterFile = fullfile(outputFolder,'consensus_model_parameters.csv');
overallFile = fullfile(outputFolder,'consensus_model_parameter_summary.csv');
groupFile = fullfile(outputFolder,'consensus_model_group_summary.csv');
errorFile = fullfile(outputFolder,'consensus_model_fit_errors.csv');
initialShearFile = fullfile(outputFolder,'consensus_initial_shear_modulus_values.csv');
initialShearSummaryFile = fullfile(outputFolder,'consensus_initial_shear_modulus_summary.csv');
initialShearErrorFile = fullfile(outputFolder,'consensus_initial_shear_modulus_errors.csv');
dataFile = fullfile(outputFolder,'consensus_model_population.mat');

if isfield(population,'modelSelectionSummary')
    writetable(population.modelSelectionSummary, selectionFile);
else
    writetable(table(), selectionFile);
end
writetable(population.parameterTable, parameterFile);
writetable(population.overallSummary, overallFile);

files.selection = string(selectionFile);
files.parameters = string(parameterFile);
files.overall = string(overallFile);

if ~isempty(population.groupSummary)
    writetable(population.groupSummary, groupFile);
    files.groups = string(groupFile);
end
if ~isempty(population.extractionErrors)
    writetable(population.extractionErrors, errorFile);
    files.errors = string(errorFile);
end

if isfield(population,'initialShearModulus')
    writetable(population.initialShearModulus.values, initialShearFile);
    writetable(population.initialShearModulus.summary, initialShearSummaryFile);
    files.initialShearValues = string(initialShearFile);
    files.initialShearSummary = string(initialShearSummaryFile);
    if ~isempty(population.initialShearModulus.errors)
        writetable(population.initialShearModulus.errors, initialShearErrorFile);
        files.initialShearErrors = string(initialShearErrorFile);
    end
end

parameterFigure = mechanics.plotting.plotSelectedParameterPopulation(population);
parameterCleanup = onCleanup(@() close(parameterFigure)); %#ok<NASGU>
parameterFigureFile = mechanics.plotting.exportFigureFiles( ...
    parameterFigure, outputFolder, "consensus_model_parameters", "png", 200);

if isfield(population,'initialShearModulus')
    initialShearFigure = ...
        mechanics.plotting.plotInitialShearModulusPopulation(population);
    initialShearCleanup = onCleanup(@() close(initialShearFigure)); %#ok<NASGU>
    initialShearFigureFile = mechanics.plotting.exportFigureFiles( ...
        initialShearFigure, outputFolder, ...
        "consensus_initial_shear_modulus", "png", 200);
    files.initialShearFigure = string(initialShearFigureFile);
end

save(dataFile,'population');
files.parameterFigure = string(parameterFigureFile);
files.data = string(dataFile);
end