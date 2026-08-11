function outputFiles = exportPopulationAnalysis(population, outputFolder, options)
%EXPORTPOPULATIONANALYSIS Export population curves and statistical summaries.
arguments
    population (1,1) struct
    outputFolder (1,1) string
    options.SaveData (1,1) logical = true
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
tangentModulusFile = fullfile( ...
    outputFolder, "population_tangent_modulus.csv");
metricFile = fullfile(outputFolder, "population_metrics.csv");
modelSelectionSummaryFile = fullfile( ...
    outputFolder, "individual_model_selection_summary.csv");
parameterValueFile = fullfile( ...
    outputFolder, "individual_selected_model_parameter_values.csv");
parameterSummaryFile = fullfile( ...
    outputFolder, "individual_selected_model_parameter_summary.csv");

writetable(curveTable, curveFile);

if isfield(population, "tangentModulus") && ...
        ~isempty(fieldnames(population.tangentModulus))
    tangent = population.tangentModulus;
    tangentCentralStatistic = repmat(string(tangent.centralStatistic), ...
        numel(tangent.strain), 1);
    [summaryCentralStatistic, summaryValue, summaryRangeMode, ...
        summaryRange] = localTangentSummaryColumns(tangent, numel(tangent.strain));
    tangentTable = table( ...
        tangent.strain, tangent.meanModulus, tangent.medianModulus, ...
        tangent.centralModulus, tangentCentralStatistic, ...
        tangent.standardDeviation, tangent.standardError, ...
        tangent.confidenceLower, tangent.confidenceUpper, ...
        tangent.specimenCountByPoint, summaryCentralStatistic, ...
        summaryValue, summaryRangeMode, summaryRange(:, 1), summaryRange(:, 2), ...
        'VariableNames', { ...
            'Strain', 'MeanModulus', 'MedianModulus', 'CentralModulus', ...
            'CentralStatistic', 'StandardDeviation', 'StandardError', ...
            'ConfidenceLower', 'ConfidenceUpper', 'SpecimenCount', ...
            'SummaryCentralStatistic', 'SummaryValue', 'SummaryRangeMode', ...
            'SummaryRangeLower', 'SummaryRangeUpper'});
    writetable(tangentTable, tangentModulusFile);
    outputFiles.tangentModulus = string(tangentModulusFile);
end

writetable(population.metrics, metricFile);
if isfield(population, "modelSelection") && ...
        isfield(population.modelSelection, "summary")
    writetable(population.modelSelection.summary, modelSelectionSummaryFile);
    outputFiles.modelSelectionSummary = string(modelSelectionSummaryFile);
end
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

outputFiles.curve = string(curveFile);
outputFiles.metrics = string(metricFile);
outputFiles.parameterValues = string(parameterValueFile);
outputFiles.parameterSummary = string(parameterSummaryFile);

if options.SaveData
    populationFile = fullfile(outputFolder, "population_analysis.mat");
    save(populationFile, "population");
    outputFiles.population = string(populationFile);
end
end

function [centralStatistic, value, rangeMode, range] = ...
        localTangentSummaryColumns(tangent, rowCount)
centralStatistic = repmat("unavailable", rowCount, 1);
value = nan(rowCount, 1);
rangeMode = repmat("unavailable", rowCount, 1);
range = nan(rowCount, 2);
if ~isfield(tangent, "summary") || isempty(tangent.summary)
    return;
end
summary = tangent.summary;
centralStatistic(:) = string(summary.centralStatistic);
value(:) = double(summary.value);
rangeMode(:) = string(summary.rangeMode);
range(:, :) = repmat(double(summary.configuredRange(:)'), rowCount, 1);
end
