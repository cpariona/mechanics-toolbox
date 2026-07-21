function assessment = assessFitReliability( ...
        fitResult, uncertainty, identifiability, windowStability, ...
        residualDiagnostics, config)
%ASSESSFITRELIABILITY Combine fit-quality diagnostics into one assessment.
arguments
    fitResult (1,1) struct
    uncertainty (1,1) struct = struct()
    identifiability (1,1) struct = struct()
    windowStability (1,1) struct = struct()
    residualDiagnostics (1,1) struct = struct()
    config (1,1) struct = mechanics.config.fitReliabilityConfig()
end

requiredFit = ["modelName", "converged", "metrics"];
if ~all(isfield(fitResult, requiredFit))
    error("mechanics:fitting:InvalidReliabilityFitResult", ...
        "fitResult is missing fields required for reliability assessment.");
end

component = strings(0,1);
available = false(0,1);
flagged = false(0,1);
detail = strings(0,1);

[component, available, flagged, detail] = localAppend( ...
    component, available, flagged, detail, ...
    "Convergence", true, ~logical(fitResult.converged), ...
    localBooleanDetail(fitResult.converged, ...
        "Optimizer converged", "Optimizer did not converge"));

metrics = fitResult.metrics;
fitQualityAvailable = isfield(metrics, "normalizedRmse") && ...
    isfield(metrics, "rSquared");
if fitQualityAvailable
    poorFit = (~isfinite(metrics.normalizedRmse) || ...
        metrics.normalizedRmse > config.maximumAcceptableNormalizedRmse) || ...
        (~isfinite(metrics.rSquared) || ...
        metrics.rSquared < config.minimumAcceptableRSquared);
    fitDetail = sprintf("NRMSE=%.4g; R2=%.4g", ...
        metrics.normalizedRmse, metrics.rSquared);
else
    poorFit = false;
    fitDetail = "Fit metrics unavailable";
end
[component, available, flagged, detail] = localAppend( ...
    component, available, flagged, detail, ...
    "FitQuality", fitQualityAvailable, poorFit, fitDetail);

uncertaintyAvailable = isfield(uncertainty, "successfulFraction");
if uncertaintyAvailable
    uncertaintyFlag = uncertainty.successfulFraction < ...
        config.minimumBootstrapSuccessFraction;
    uncertaintyDetail = sprintf("Bootstrap success=%.1f%%", ...
        100 * uncertainty.successfulFraction);
else
    uncertaintyFlag = false;
    uncertaintyDetail = "Bootstrap uncertainty unavailable";
end
[component, available, flagged, detail] = localAppend( ...
    component, available, flagged, detail, ...
    "Bootstrap", uncertaintyAvailable, uncertaintyFlag, uncertaintyDetail);

identifiabilityAvailable = isfield(identifiability, "weaklyIdentified");
if identifiabilityAvailable
    identifiabilityFlag = logical(identifiability.weaklyIdentified);
    identifiabilityDetail = localBooleanDetail(~identifiabilityFlag, ...
        "Parameters identifiable", "Weak parameter identifiability detected");
else
    identifiabilityFlag = false;
    identifiabilityDetail = "Identifiability diagnostics unavailable";
end
[component, available, flagged, detail] = localAppend( ...
    component, available, flagged, detail, ...
    "Identifiability", identifiabilityAvailable, ...
    identifiabilityFlag, identifiabilityDetail);

windowAvailable = isfield(windowStability, "stable");
if windowAvailable
    windowFlag = ~logical(windowStability.stable);
    windowDetail = localBooleanDetail(~windowFlag, ...
        "Parameters stable across windows", ...
        "Window-dependent parameters detected");
else
    windowFlag = false;
    windowDetail = "Window-stability diagnostics unavailable";
end
[component, available, flagged, detail] = localAppend( ...
    component, available, flagged, detail, ...
    "WindowStability", windowAvailable, windowFlag, windowDetail);

residualAvailable = isfield(residualDiagnostics, "hasSystematicStructure");
if residualAvailable
    residualFlag = logical(residualDiagnostics.hasSystematicStructure);
    residualDetail = localBooleanDetail(~residualFlag, ...
        "No systematic residual structure", ...
        "Systematic residual structure detected");
else
    residualFlag = false;
    residualDetail = "Residual diagnostics unavailable";
end
[component, available, flagged, detail] = localAppend( ...
    component, available, flagged, detail, ...
    "Residuals", residualAvailable, residualFlag, residualDetail);

flagCount = nnz(flagged & available);
availableCount = nnz(available);
missingCount = nnz(~available);

if config.requireAllDiagnostics && missingCount > 0
    status = "incomplete";
elseif flagCount <= config.reliableMaximumFlagCount
    status = "reliable";
elseif flagCount <= config.cautionMaximumFlagCount
    status = "caution";
else
    status = "unreliable";
end

componentSummary = table(component, available, flagged, detail, ...
    'VariableNames', {'Component','Available','Flagged','Detail'});

assessment.modelName = string(fitResult.modelName);
assessment.status = status;
assessment.flagCount = flagCount;
assessment.availableComponentCount = availableCount;
assessment.missingComponentCount = missingCount;
assessment.componentSummary = componentSummary;
assessment.flaggedComponents = component(flagged & available);
assessment.missingComponents = component(~available);
assessment.config = config;
end

function [component, available, flagged, detail] = localAppend( ...
        component, available, flagged, detail, name, isAvailable, isFlagged, text)
component(end+1,1) = string(name);
available(end+1,1) = logical(isAvailable);
flagged(end+1,1) = logical(isFlagged);
detail(end+1,1) = string(text);
end

function text = localBooleanDetail(condition, positiveText, negativeText)
if condition
    text = string(positiveText);
else
    text = string(negativeText);
end
end
