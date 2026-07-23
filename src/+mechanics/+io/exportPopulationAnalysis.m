function outputFiles = exportPopulationAnalysis(population, outputFolder)
%EXPORTPOPULATIONANALYSIS Export population curves and statistical summaries.
arguments
    population (1,1) struct
    outputFolder (1,1) string
end

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

curves = population.curves;
if ~isfield(curves, "medianStress")
    curves.medianStress = nan(size(curves.meanStress));
end
if ~isfield(curves, "centralStress")
    curves.centralStress = curves.meanStress;
end
if ~isfield(curves, "centralStatistic")
    curves.centralStatistic = "mean";
end
centralStatistic = repmat(string(curves.centralStatistic), ...
    numel(curves.strain), 1);

curveTable = table( ...
    curves.strain, curves.meanStress, curves.medianStress, ...
    curves.centralStress, centralStatistic, ...
    curves.standardDeviation, curves.standardError, ...
    curves.confidenceLower, curves.confidenceUpper, ...
    'VariableNames', { ...
        'Strain', 'MeanStress', 'MedianStress', 'CentralStress', ...
        'CentralStatistic', 'StandardDeviation', 'StandardError', ...
        'ConfidenceLower', 'ConfidenceUpper'});

curveFile = fullfile(outputFolder, "population_curve.csv");
metricFile = fullfile(outputFolder, "population_metrics.csv");
parameterValueFile = fullfile( ...
    outputFolder, "selected_model_parameter_values.csv");
parameterSummaryFile = fullfile( ...
    outputFolder, "selected_model_parameter_summary.csv");
populationFile = fullfile(outputFolder, "population_analysis.mat");

writetable(curveTable, curveFile);
writetable(population.metrics, metricFile);
if ~isempty(population.modelParameters.values)
    writetable(population.modelParameters.values, parameterValueFile);
else
    writetable(table(), parameterValueFile);
end
if ~isempty(population.modelParameters.summary)
    writetable(population.modelParameters.summary, parameterSummaryFile);
else
    writetable(table(), parameterSummaryFile);
end
save(populationFile, "population");

outputFiles.curve = string(curveFile);
outputFiles.metrics = string(metricFile);
outputFiles.parameterValues = string(parameterValueFile);
outputFiles.parameterSummary = string(parameterSummaryFile);
outputFiles.population = string(populationFile);
end