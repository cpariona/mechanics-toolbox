function outputFiles = exportTensileApplicationRangeCharacterization( ...
    result, outputFolder)
%EXPORTTENSILEAPPLICATIONRANGECHARACTERIZATION Export maintained outputs.
arguments
    result (1,1) struct
    outputFolder (1,1) string
end

required = ["candidateSummary", "selectedModelName", "selectedFit", ...
    "referenceProperties", "rangeSensitivity"];
if ~all(isfield(result, required))
    error("mechanics:io:InvalidTensileApplicationRangeCharacterization", ...
        "Provide a completed tensile application-range result.");
end
folder = string(outputFolder);
if ~isfolder(folder)
    mkdir(folder);
end

candidateFile = fullfile(folder, "candidate_model_summary.csv");
writetable(result.candidateSummary, candidateFile);
outputFiles.candidateSummary = string(candidateFile);

selectedParameters = table( ...
    string(result.selectedFit.parameterNames(:)), ...
    reshape(double(result.selectedFit.parameters), [], 1), ...
    'VariableNames', {'Parameter','Estimate'});
parameterFile = fullfile(folder, "selected_parameters.csv");
writetable(selectedParameters, parameterFile);
outputFiles.selectedParameters = string(parameterFile);

referenceProperties = table( ...
    string(result.referenceProperties.names(:)), ...
    reshape(double(result.referenceProperties.values), [], 1), ...
    'VariableNames', {'Property','Estimate'});
referenceFile = fullfile(folder, "reference_properties.csv");
writetable(referenceProperties, referenceFile);
outputFiles.referenceProperties = string(referenceFile);

specimenFile = fullfile(folder, "tensile_specimen_fit_summary.csv");
writetable(result.selectedFit.specimenSummary, specimenFile);
outputFiles.tensileSpecimenSummary = string(specimenFile);

sensitivityFile = fullfile(folder, "range_sensitivity_summary.csv");
writetable(result.rangeSensitivity.scenarioSummary, sensitivityFile);
outputFiles.rangeSensitivitySummary = string(sensitivityFile);

if isfield(result, "hasCompressionValidation") && ...
        result.hasCompressionValidation
    compressionFile = fullfile(folder, "compression_validation_summary.csv");
    writetable(result.compressionValidation.specimenSummary, compressionFile);
    outputFiles.compressionValidationSummary = string(compressionFile);
end

matFile = fullfile(folder, "tensile_application_range_characterization.mat");
save(matFile, "result");
outputFiles.result = string(matFile);

reportFile = fullfile(folder, "tensile_application_range_characterization.md");
localWriteReport(reportFile, result, selectedParameters, ...
    referenceProperties);
outputFiles.report = string(reportFile);
end

function localWriteReport(reportFile, result, selectedParameters, properties)
fileId = fopen(reportFile, "w");
if fileId < 0
    error("mechanics:io:ReportFileOpenFailed", ...
        "Could not open report file: %s", reportFile);
end
cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>

fprintf(fileId, "# Tensile application-range characterization\n\n");
fprintf(fileId, "Generated: %s\n\n", char(string(result.createdAt)));
fprintf(fileId, "Fitted range requested: [%g, %g]\n\n", ...
    result.config.fitRange(1), result.config.fitRange(2));
fprintf(fileId, "Selected model: `%s`\n\n", ...
    char(string(result.selectedModelName)));

fprintf(fileId, "## Selected parameters\n\n");
localWriteTable(fileId, selectedParameters);
fprintf(fileId, "## Reference properties\n\n");
localWriteTable(fileId, properties);
fprintf(fileId, "## Candidate models\n\n");
localWriteTable(fileId, result.candidateSummary);
fprintf(fileId, "## Tensile specimen fit summary\n\n");
localWriteTable(fileId, result.selectedFit.specimenSummary);
fprintf(fileId, "## Range sensitivity\n\n");
localWriteTable(fileId, result.rangeSensitivity.scenarioSummary);

if isfield(result, "hasCompressionValidation") && ...
        result.hasCompressionValidation
    fprintf(fileId, "## Compression validation\n\n");
    fprintf(fileId, "Refitting performed: `%s`\n\n", ...
        char(string(result.compressionValidation.refitPerformed)));
    fprintf(fileId, "Mean RMSE: %.6g\n\n", ...
        result.compressionValidation.meanRMSE);
    fprintf(fileId, "Mean normalized RMSE: %.6g\n\n", ...
        result.compressionValidation.meanNormalizedRMSE);
    localWriteTable(fileId, result.compressionValidation.specimenSummary);
end

fprintf(fileId, "## Interpretation boundaries\n\n");
fprintf(fileId, "- The selected model is conditional on the configured candidates, bounds, normalization, and fitted tensile range.\n");
fprintf(fileId, "- Range sensitivity varies only the upper fitted deformation boundary.\n");
fprintf(fileId, "- Compression, when supplied, is external prediction validation with fixed tensile-calibrated parameters and does not affect selection.\n");
end

function localWriteTable(fileId, input)
variables = string(input.Properties.VariableNames);
fprintf(fileId, "| %s |\n", char(strjoin(variables, " | ")));
fprintf(fileId, "|%s|\n", ...
    char(strjoin(repmat("---", 1, numel(variables)), "|")));
for row = 1:height(input)
    values = strings(1, numel(variables));
    for column = 1:numel(variables)
        value = input{row, column};
        if iscell(value)
            value = value{1};
        end
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
    if isempty(value) || ~isscalar(value)
        output = "";
    elseif isnan(value)
        output = "NaN";
    elseif isinf(value)
        output = string(value);
    else
        output = string(sprintf("%.6g", value));
    end
elseif isdatetime(value)
    output = string(value);
else
    output = replace(string(value), "|", "\\|");
end
end
