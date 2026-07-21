function diagnostics = analyzeFitResiduals(fitResult, config)
%ANALYZEFITRESIDUALS Diagnose systematic structure in fitting residuals.
arguments
    fitResult (1,1) struct
    config (1,1) struct = mechanics.config.residualDiagnosticsConfig()
end

required = ["deformation", "measuredStress", "predictedStress", "residuals"];
if ~all(isfield(fitResult, required))
    error("mechanics:fitting:InvalidResidualDiagnosticsInput", ...
        "fitResult is missing fields required for residual diagnostics.");
end

x = fitResult.deformation(:);
y = fitResult.measuredStress(:);
yhat = fitResult.predictedStress(:);
residual = fitResult.residuals(:);

if any([numel(x), numel(y), numel(yhat)] ~= numel(residual))
    error("mechanics:fitting:ResidualDiagnosticsSizeMismatch", ...
        "Fit-result vectors must have equal lengths.");
end

valid = isfinite(x) & isfinite(y) & isfinite(yhat) & isfinite(residual);
x = x(valid);
y = y(valid);
yhat = yhat(valid);
residual = residual(valid);

observationCount = numel(residual);
if observationCount < config.minimumObservations
    error("mechanics:fitting:InsufficientResidualObservations", ...
        "At least %d finite observations are required.", ...
        config.minimumObservations);
end

residualMean = mean(residual);
residualStandardDeviation = std(residual, 0);
residualScale = max(residualStandardDeviation, config.normalizationFloor);
standardizedResidual = (residual - residualMean) ./ residualScale;
outlierMask = abs(standardizedResidual) > ...
    config.standardizedResidualThreshold;

lagOneAutocorrelation = localCorrelation( ...
    residual(1:end-1), residual(2:end));
deformationCorrelation = localCorrelation(x, residual);
heteroscedasticityCorrelation = localCorrelation( ...
    abs(residual), abs(yhat));

hasAutocorrelation = isfinite(lagOneAutocorrelation) && ...
    abs(lagOneAutocorrelation) >= config.autocorrelationThreshold;
hasDeformationTrend = isfinite(deformationCorrelation) && ...
    abs(deformationCorrelation) >= ...
    config.deformationCorrelationThreshold;
hasHeteroscedasticity = isfinite(heteroscedasticityCorrelation) && ...
    abs(heteroscedasticityCorrelation) >= ...
    config.heteroscedasticityCorrelationThreshold;
hasOutliers = any(outlierMask);

observationSummary = table( ...
    (1:observationCount)', x, y, yhat, residual, standardizedResidual, ...
    outlierMask, ...
    'VariableNames', {'Index', 'Deformation', 'MeasuredStress', ...
    'PredictedStress', 'Residual', 'StandardizedResidual', 'Outlier'});

metric = ["ObservationCount"; "ResidualMean"; ...
    "ResidualStandardDeviation"; "RMSE"; "MAE"; ...
    "MaximumAbsoluteResidual"; "LagOneAutocorrelation"; ...
    "DeformationResidualCorrelation"; ...
    "AbsoluteResidualFittedMagnitudeCorrelation"; "OutlierCount"];
value = [observationCount; residualMean; residualStandardDeviation; ...
    sqrt(mean(residual.^2)); mean(abs(residual)); max(abs(residual)); ...
    lagOneAutocorrelation; deformationCorrelation; ...
    heteroscedasticityCorrelation; nnz(outlierMask)];
metricSummary = table(metric, value, ...
    'VariableNames', {'Metric', 'Value'});

diagnostics.observationCount = observationCount;
diagnostics.deformation = x;
diagnostics.measuredStress = y;
diagnostics.predictedStress = yhat;
diagnostics.residual = residual;
diagnostics.standardizedResidual = standardizedResidual;
diagnostics.outlierMask = outlierMask;
diagnostics.residualMean = residualMean;
diagnostics.residualStandardDeviation = residualStandardDeviation;
diagnostics.lagOneAutocorrelation = lagOneAutocorrelation;
diagnostics.deformationCorrelation = deformationCorrelation;
diagnostics.heteroscedasticityCorrelation = heteroscedasticityCorrelation;
diagnostics.hasAutocorrelation = hasAutocorrelation;
diagnostics.hasDeformationTrend = hasDeformationTrend;
diagnostics.hasHeteroscedasticity = hasHeteroscedasticity;
diagnostics.hasOutliers = hasOutliers;
diagnostics.hasSystematicStructure = hasAutocorrelation || ...
    hasDeformationTrend || hasHeteroscedasticity || hasOutliers;
diagnostics.observationSummary = observationSummary;
diagnostics.metricSummary = metricSummary;
diagnostics.config = config;
end

function value = localCorrelation(first, second)
first = first(:);
second = second(:);
valid = isfinite(first) & isfinite(second);
first = first(valid);
second = second(valid);

if numel(first) < 2 || std(first) == 0 || std(second) == 0
    value = NaN;
    return;
end

matrix = corrcoef(first, second);
value = matrix(1, 2);
end
