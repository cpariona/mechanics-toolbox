function audit = summarizeFittingAudit(study)
%SUMMARIZEFITTINGAUDIT Summarize stored fitting windows without refitting.
arguments
    study (1,1) struct
end

modelRows = struct([]);
windowRows = struct([]);
modelRowIndex = 0;
windowRowIndex = 0;

if ~isfield(study, "analysis") || ~isfield(study.analysis, "records")
    audit.modelSummary = table();
    audit.windowSummary = table();
    audit.status = "unavailable";
    return;
end

records = study.analysis.records;
for recordIndex = 1:numel(records)
    record = records(recordIndex);
    if string(record.status) ~= "processed" || ...
            ~isfield(record.specimen, "modelSelection")
        continue;
    end

    selection = record.specimen.modelSelection;
    specimenId = string(record.specimenId);
    bestModel = "";
    if isfield(selection, "selection") && ...
            isfield(selection.selection, "bestModel")
        bestModel = string(selection.selection.bestModel);
    end

    if isfield(selection, "summary") && ~isempty(selection.summary)
        summary = selection.summary;
        variables = string(summary.Properties.VariableNames);
        selectedMask = string(summary.Model) == bestModel;
        selectedRMSE = NaN;
        if any(selectedMask)
            selectedRMSE = summary.FullWindowRMSE(find(selectedMask, 1));
        end
        for row = 1:height(summary)
            modelRowIndex = modelRowIndex + 1;
            modelRows(modelRowIndex).SpecimenId = specimenId; %#ok<AGROW>
            modelRows(modelRowIndex).Model = string(summary.Model(row));
            modelRows(modelRowIndex).WindowCount = summary.WindowCount(row);
            modelRows(modelRowIndex).SuccessfulWindowCount = ...
                summary.SuccessfulWindowCount(row);
            modelRows(modelRowIndex).ConvergedWindowCount = ...
                summary.ConvergedWindowCount(row);
            modelRows(modelRowIndex).FullWindowRMSE = summary.FullWindowRMSE(row);
            modelRows(modelRowIndex).FullWindowRSquared = ...
                summary.FullWindowRSquared(row);
            modelRows(modelRowIndex).FullWindowAIC = summary.FullWindowAIC(row);
            modelRows(modelRowIndex).FullWindowBIC = summary.FullWindowBIC(row);
            modelRows(modelRowIndex).MaximumRelativeParameterCV = ...
                summary.MaximumRelativeParameterCV(row);
            modelRows(modelRowIndex).DominantCVParameter = ...
                localOptionalValue(summary, variables, ...
                "DominantCVParameter", row, "");
            modelRows(modelRowIndex).HasParameterSignChange = ...
                localOptionalValue(summary, variables, ...
                "HasParameterSignChange", row, false);
            modelRows(modelRowIndex).MaximumSharedDomainNormalizedRMSE = ...
                localOptionalValue(summary, variables, ...
                "MaximumSharedDomainNormalizedRMSE", row, NaN);
            modelRows(modelRowIndex).MaximumSharedDomainNormalizedMaxError = ...
                localOptionalValue(summary, variables, ...
                "MaximumSharedDomainNormalizedMaxError", row, NaN);
            modelRows(modelRowIndex).LowerRMSEThanSelected = ...
                isfinite(selectedRMSE) && ...
                summary.FullWindowRMSE(row) < selectedRMSE;
            modelRows(modelRowIndex).Eligible = summary.Eligible(row);
            modelRows(modelRowIndex).Selected = ...
                string(summary.Model(row)) == bestModel;
        end
    end

    if ~isfield(selection, "records")
        continue;
    end
    fitRecords = selection.records;
    for fitIndex = 1:numel(fitRecords)
        fitRecord = fitRecords(fitIndex);
        windowRowIndex = windowRowIndex + 1;
        windowRows(windowRowIndex).SpecimenId = specimenId; %#ok<AGROW>
        windowRows(windowRowIndex).Model = string(fitRecord.modelName);
        windowRows(windowRowIndex).WindowFraction = fitRecord.windowFraction;
        windowRows(windowRowIndex).MaximumDeformation = ...
            fitRecord.maximumDeformation;
        windowRows(windowRowIndex).ObservationCount = ...
            fitRecord.observationCount;
        windowRows(windowRowIndex).Succeeded = logical(fitRecord.succeeded);
        windowRows(windowRowIndex).Converged = false;
        windowRows(windowRowIndex).ParameterEstimates = "";
        windowRows(windowRowIndex).InitialShearModulus = NaN;
        windowRows(windowRowIndex).RMSE = NaN;
        windowRows(windowRowIndex).RSquared = NaN;
        windowRows(windowRowIndex).AIC = NaN;
        windowRows(windowRowIndex).BIC = NaN;
        windowRows(windowRowIndex).ErrorIdentifier = ...
            string(fitRecord.errorIdentifier);

        if ~fitRecord.succeeded
            continue;
        end
        fit = fitRecord.fitResult;
        windowRows(windowRowIndex).Converged = logical(fit.converged);
        windowRows(windowRowIndex).ParameterEstimates = ...
            localParameterText(fit.parameterNames, fit.parameters);
        windowRows(windowRowIndex).InitialShearModulus = ...
            localInitialShearModulus(fit.modelName, ...
                fit.parameterNames, fit.parameters);
        windowRows(windowRowIndex).RMSE = localMetric(fit.metrics, "rmse");
        windowRows(windowRowIndex).RSquared = ...
            localMetric(fit.metrics, "rSquared");
        windowRows(windowRowIndex).AIC = localMetric(fit.metrics, "aic");
        windowRows(windowRowIndex).BIC = localMetric(fit.metrics, "bic");
    end
end

if isempty(modelRows)
    audit.modelSummary = table();
else
    audit.modelSummary = struct2table(modelRows);
end
if isempty(windowRows)
    audit.windowSummary = table();
else
    audit.windowSummary = struct2table(windowRows);
end
if isempty(modelRows) && isempty(windowRows)
    audit.status = "unavailable";
else
    audit.status = "completed";
end
end

function value = localOptionalValue(summary, variables, name, row, fallback)
value = fallback;
if ismember(name, variables)
    raw = summary.(name)(row);
    if iscell(raw) && isscalar(raw)
        raw = raw{1};
    end
    value = raw;
end
end

function text = localParameterText(names, values)
names = string(names(:));
values = values(:);
parts = strings(numel(names), 1);
for index = 1:numel(names)
    parts(index) = names(index) + "=" + compose("%.6g", values(index));
end
text = strjoin(parts, ", ");
end

function value = localInitialShearModulus(modelName, names, parameters)
value = NaN;
model = mechanics.models.modelRegistry(string(modelName));
derivedNames = string(model.derivedQuantityNames(:));
mu0Index = find(derivedNames == "mu0", 1, "first");
if isempty(mu0Index) || isempty(model.evaluateDerivedQuantities)
    return;
end

expectedNames = string(model.parameterNames(:));
fitNames = string(names(:));
fitParameters = parameters(:);
if numel(expectedNames) ~= numel(fitParameters)
    return;
end

orderedParameters = zeros(numel(expectedNames), 1);
for index = 1:numel(expectedNames)
    match = strcmpi(fitNames, expectedNames(index));
    if nnz(match) ~= 1
        return;
    end
    orderedParameters(index) = fitParameters(match);
end

derivedValues = reshape(double( ...
    model.evaluateDerivedQuantities(orderedParameters)), [], 1);
if numel(derivedValues) ~= numel(derivedNames)
    return;
end
value = derivedValues(mu0Index);
end

function value = localMetric(metrics, fieldName)
value = NaN;
if isfield(metrics, fieldName)
    value = metrics.(fieldName);
end
end
