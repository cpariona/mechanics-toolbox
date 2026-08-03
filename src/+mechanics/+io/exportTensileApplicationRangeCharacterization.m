function outputFiles = exportTensileApplicationRangeCharacterization( ...
    result, outputFolder)
%EXPORTTENSILEAPPLICATIONRANGECHARACTERIZATION Export maintained outputs.
arguments
    result (1,1) struct
    outputFolder (1,1) string
end
required = ["candidateSummary", "selectedModelName", "selectedFit", "referenceProperties", "rangeSensitivity"];
if ~all(isfield(result, required))
    error("mechanics:io:InvalidTensileApplicationRangeCharacterization", "Provide a completed tensile application-range result.");
end
folder = string(outputFolder);
if ~isfolder(folder), mkdir(folder); end
units = localUnits(result);

candidateFile = fullfile(folder, "candidate_model_summary.csv");
writetable(result.candidateSummary, candidateFile);
outputFiles.candidateSummary = string(candidateFile);

parameterCount = numel(result.selectedFit.parameters);
selectedParameters = table(string(result.selectedFit.parameterNames(:)), reshape(double(result.selectedFit.parameters), [], 1), repmat(units.stress, parameterCount, 1), 'VariableNames', {'Parameter','Estimate','Unit'});
parameterFile = fullfile(folder, "selected_parameters.csv");
writetable(selectedParameters, parameterFile);
outputFiles.selectedParameters = string(parameterFile);

propertyCount = numel(result.referenceProperties.values);
referenceProperties = table(string(result.referenceProperties.names(:)), reshape(double(result.referenceProperties.values), [], 1), repmat(units.stress, propertyCount, 1), 'VariableNames', {'Property','Estimate','Unit'});
referenceFile = fullfile(folder, "reference_properties.csv");
writetable(referenceProperties, referenceFile);
outputFiles.referenceProperties = string(referenceFile);

specimenSummary = result.selectedFit.specimenSummary;
specimenSummary.StrainUnit = repmat(units.strain, height(specimenSummary), 1);
specimenSummary.StressUnit = repmat(units.stress, height(specimenSummary), 1);
specimenFile = fullfile(folder, "tensile_specimen_fit_summary.csv");
writetable(specimenSummary, specimenFile);
outputFiles.tensileSpecimenSummary = string(specimenFile);

sensitivitySummary = result.rangeSensitivity.scenarioSummary;
sensitivitySummary.MaximumDeformationUnit = repmat(units.strain, height(sensitivitySummary), 1);
sensitivitySummary.Mu0Unit = repmat(units.stress, height(sensitivitySummary), 1);
sensitivityFile = fullfile(folder, "range_sensitivity_summary.csv");
writetable(sensitivitySummary, sensitivityFile);
outputFiles.rangeSensitivitySummary = string(sensitivityFile);

compressionSummary = table();
if isfield(result, "hasCompressionValidation") && result.hasCompressionValidation
    compressionUnits = localCompressionUnits(result);
    compressionSummary = result.compressionValidation.specimenSummary;
    compressionSummary.StrainUnit = repmat(compressionUnits.strain, height(compressionSummary), 1);
    compressionSummary.StressUnit = repmat(compressionUnits.stress, height(compressionSummary), 1);
    compressionFile = fullfile(folder, "compression_validation_summary.csv");
    writetable(compressionSummary, compressionFile);
    outputFiles.compressionValidationSummary = string(compressionFile);
end

outputFiles = localExportFigures(result, folder, outputFiles);
matFile = fullfile(folder, "tensile_application_range_characterization.mat");
save(matFile, "result");
outputFiles.result = string(matFile);
reportFile = fullfile(folder, "tensile_application_range_characterization.md");
localWriteReport(reportFile, result, selectedParameters, referenceProperties, specimenSummary, sensitivitySummary, compressionSummary, outputFiles, units);
outputFiles.report = string(reportFile);
end

function outputFiles = localExportFigures(result, folder, outputFiles)
fitFigure = mechanics.plotting.plotTensileApplicationRangeFit(result);
cleanup = onCleanup(@() delete(fitFigure)); %#ok<NASGU>
outputFiles.tensileFitFigure = mechanics.plotting.exportFigureFiles(fitFigure, folder, "tensile_fit_and_residuals", "png", 200);
outputFiles.tensileFitFigureFig = string(fullfile(folder, "tensile_fit_and_residuals.fig"));
clear cleanup
sensitivityFigure = mechanics.plotting.plotTensileApplicationRangeSensitivity(result);
cleanup = onCleanup(@() delete(sensitivityFigure)); %#ok<NASGU>
outputFiles.rangeSensitivityFigure = mechanics.plotting.exportFigureFiles(sensitivityFigure, folder, "range_sensitivity", "png", 200);
outputFiles.rangeSensitivityFigureFig = string(fullfile(folder, "range_sensitivity.fig"));
clear cleanup
if isfield(result, "hasCompressionValidation") && result.hasCompressionValidation
    compressionFigure = mechanics.plotting.plotTensileApplicationRangeCompressionValidation(result);
    cleanup = onCleanup(@() delete(compressionFigure)); %#ok<NASGU>
    outputFiles.compressionValidationFigure = mechanics.plotting.exportFigureFiles(compressionFigure, folder, "compression_validation", "png", 200);
    outputFiles.compressionValidationFigureFig = string(fullfile(folder, "compression_validation.fig"));
    clear cleanup
end
end

function units = localUnits(result)
specimens = result.selectedFit.specimens;
if isempty(specimens) || ~all(isfield(specimens, ["StrainUnit","StressUnit"]))
    error("mechanics:io:MissingTensileApplicationRangeUnits", "Selected tensile specimens must retain strain and stress units.");
end
units.strain = string(specimens(1).StrainUnit);
units.stress = string(specimens(1).StressUnit);
for index = 2:numel(specimens)
    if string(specimens(index).StrainUnit) ~= units.strain || string(specimens(index).StressUnit) ~= units.stress
        error("mechanics:io:InconsistentTensileApplicationRangeUnits", "Selected tensile specimens must share units.");
    end
end
end

function units = localCompressionUnits(result)
specimens = result.compressionValidation.specimens;
units.strain = string(specimens(1).StrainUnit);
units.stress = string(specimens(1).StressUnit);
end

function localWriteReport(reportFile, result, selectedParameters, properties, specimenSummary, sensitivitySummary, compressionSummary, outputFiles, units)
fileId = fopen(reportFile, "w");
if fileId < 0, error("mechanics:io:ReportFileOpenFailed", "Could not open report file: %s", reportFile); end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId, "# Tensile application-range characterization\n\n");
fprintf(fileId, "Generated: %s\n\n", char(string(result.createdAt)));
fprintf(fileId, "Deformation unit: `%s`\n\n", char(units.strain));
fprintf(fileId, "Stress and parameter unit: `%s`\n\n", char(units.stress));
fprintf(fileId, "Fitted range requested: [%g, %g] %s\n\n", result.config.fitRange(1), result.config.fitRange(2), char(units.strain));
fprintf(fileId, "Selected model: `%s`\n\n", char(string(result.selectedModelName)));
fprintf(fileId, "## Selected parameters\n\n"); localWriteTable(fileId, selectedParameters);
fprintf(fileId, "## Reference properties\n\n"); localWriteTable(fileId, properties);
fprintf(fileId, "## Candidate models\n\n"); localWriteTable(fileId, result.candidateSummary);
fprintf(fileId, "## Tensile specimen fit summary\n\n"); localWriteTable(fileId, specimenSummary);
localWriteFigure(fileId, "Tensile fits and residuals", outputFiles.tensileFitFigure);
fprintf(fileId, "## Range sensitivity\n\n"); localWriteTable(fileId, sensitivitySummary);
localWriteFigure(fileId, "Range sensitivity", outputFiles.rangeSensitivityFigure);
if isfield(result, "hasCompressionValidation") && result.hasCompressionValidation
    compressionUnits = localCompressionUnits(result);
    fprintf(fileId, "## Compression validation\n\n");
    fprintf(fileId, "Refitting performed: `%s`\n\n", char(string(result.compressionValidation.refitPerformed)));
    fprintf(fileId, "Mean RMSE: %.6g %s\n\n", result.compressionValidation.meanRMSE, char(compressionUnits.stress));
    fprintf(fileId, "Mean normalized RMSE: %.6g [1]\n\n", result.compressionValidation.meanNormalizedRMSE);
    localWriteTable(fileId, compressionSummary);
    localWriteFigure(fileId, "Compression validation", outputFiles.compressionValidationFigure);
end
fprintf(fileId, "## Interpretation boundaries\n\n");
fprintf(fileId, "- The selected model is conditional on the configured candidates, bounds, normalization, and fitted tensile range.\n");
fprintf(fileId, "- Range sensitivity varies only the upper fitted deformation boundary.\n");
fprintf(fileId, "- Compression, when supplied, is external prediction validation with fixed tensile-calibrated parameters and does not affect selection.\n");
fprintf(fileId, "- Normalized objective, normalized RMSE, and normalized loss are dimensionless.\n");
end

function localWriteFigure(fileId, titleText, filePath)
[~, name, extension] = fileparts(filePath);
fprintf(fileId, "### %s\n\n![%s](%s%s)\n\n", char(titleText), char(titleText), char(string(name)), char(string(extension)));
end

function localWriteTable(fileId, input)
variables = string(input.Properties.VariableNames);
fprintf(fileId, "| %s |\n", char(strjoin(variables, " | ")));
fprintf(fileId, "|%s|\n", char(strjoin(repmat("---", 1, numel(variables)), "|")));
for row = 1:height(input)
    values = strings(1, numel(variables));
    for column = 1:numel(variables)
        value = input{row, column};
        if iscell(value), value = value{1}; end
        values(column) = localText(value);
    end
    fprintf(fileId, "| %s |\n", char(strjoin(values, " | ")));
end
fprintf(fileId, "\n");
end

function output = localText(value)
if ismissing(value)
    output = "missing";
elseif islogical(value)
    output = string(value);
elseif isnumeric(value)
    if isempty(value) || ~isscalar(value), output = "";
    elseif isnan(value), output = "NaN";
    elseif isinf(value), output = string(value);
    else, output = string(sprintf("%.6g", value)); end
elseif isdatetime(value)
    output = string(value);
else
    output = replace(string(value), "|", "\\|");
end
end
