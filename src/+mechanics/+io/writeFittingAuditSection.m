function writeFittingAuditSection(fileId, audit, strainUnit, stressUnit)
%WRITEFITTINGAUDITSECTION Write stored fitting results into an open report.
arguments
    fileId (1,1) double
    audit (1,1) struct
    strainUnit (1,1) string = "-"
    stressUnit (1,1) string = "-"
end

if ~isfield(audit, "status") || string(audit.status) ~= "completed"
    return;
end

fprintf(fileId, "## Constitutive fitting audit\n\n");
fprintf(fileId, [ ...
    "This section summarizes the fittings already computed by the standard " + ...
    "workflow. No models are refitted during report generation.\n\n"]);

if ~isempty(audit.modelSummary)
    fprintf(fileId, "### Model eligibility and selection\n\n");
    modelSummary = audit.modelSummary(:, { ...
        'SpecimenId','Model','WindowCount','SuccessfulWindowCount', ...
        'ConvergedWindowCount','FullWindowRMSE','FullWindowRSquared', ...
        'FullWindowBIC','MaximumRelativeParameterCV','ParameterStable', ...
        'Eligible','Selected'});
    localWriteTable(fileId, modelSummary);
end

if ~isempty(audit.windowSummary)
    fprintf(fileId, "### Window-level fitting results\n\n");
    windowSummary = audit.windowSummary(:, { ...
        'SpecimenId','Model','WindowFraction','MaximumDeformation', ...
        'ObservationCount','Succeeded','Converged','ParameterEstimates', ...
        'InitialShearModulus','RMSE','RSquared','AIC','BIC'});
    localWriteTable(fileId, windowSummary);
    fprintf(fileId, ...
        "- Maximum deformation unit: `%s`.\n", char(strainUnit));
    fprintf(fileId, ...
        "- Parameter and equivalent initial shear-modulus unit: `%s`.\n", ...
        char(stressUnit));
    fprintf(fileId, [ ...
        "- Equivalent initial shear modulus is derived as `mu` for " + ...
        "Neo-Hookean, `2*(C10+C01)` for Mooney-Rivlin, and `2*C10` " + ...
        "for Yeoh.\n\n"]);
end
end

function localWriteTable(fileId, inputTable)
names = string(inputTable.Properties.VariableNames);
fprintf(fileId, "| %s |\n", char(strjoin(names, " | ")));
fprintf(fileId, "|%s|\n", char(strjoin(repmat("---", size(names)), "|")));
for row = 1:height(inputTable)
    values = strings(1, width(inputTable));
    for column = 1:width(inputTable)
        values(column) = localTableText(inputTable{row, column});
    end
    fprintf(fileId, "| %s |\n", char(strjoin(values, " | ")));
end
fprintf(fileId, "\n");
end

function text = localTableText(value)
if iscell(value) && isscalar(value)
    value = value{1};
end
if isnumeric(value) && isscalar(value)
    if isnan(value)
        text = "";
    else
        text = string(sprintf("%.6g", value));
    end
elseif islogical(value) && isscalar(value)
    text = string(value);
else
    text = string(value);
    text(ismissing(text)) = "";
    if ~isscalar(text)
        text = strjoin(text(:)', ", ");
    end
end
text = replace(text, "|", "\|");
end
