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
            modelRows(modelRowIndex).ParameterStable = summary.ParameterStable(row);
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
modelName = lower(string(modelName));
names = lower(string(names(:)));
parameters = parameters(:);
value = NaN;
switch modelName
    case "neo-hookean"
        value = localParameter(names, parameters, ["mu", "c10"]);
    case "mooney-rivlin"
        c10 = localParameter(names, parameters, "c10");
        c01 = localParameter(names, parameters, "c01");
        if isfinite(c10) && isfinite(c01)
            value = 2 .* (c10 + c01);
        end
    case "yeoh"
        c10 = localParameter(names, parameters, "c10");
        if isfinite(c10)
            value = 2 .* c10;
        end
end
end

function value = localParameter(names, parameters, candidates)
value = NaN;
candidates = string(candidates);
for candidate = candidates(:)'
    index = find(names == candidate, 1);
    if ~isempty(index)
        value = parameters(index);
        return;
    end
end
end

function value = localMetric(metrics, fieldName)
value = NaN;
if isfield(metrics, fieldName)
    value = metrics.(fieldName);
end
end
