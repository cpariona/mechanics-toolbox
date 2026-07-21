function metrics = computeFitMetrics(measuredStress, predictedStress, parameterCount)
%COMPUTEFITMETRICS Compute descriptive fitting metrics.
y = measuredStress(:);
yhat = predictedStress(:);
residual = y - yhat;
n = numel(y);
sse = sum(residual.^2);
mse = sse / n;
rmse = sqrt(mse);
mae = mean(abs(residual));
maxAbsoluteError = max(abs(residual));
sst = sum((y - mean(y)).^2);
if sst > 0
    rSquared = 1 - sse / sst;
else
    rSquared = double(sse == 0);
end
stressRange = max(y) - min(y);
if stressRange > 0
    normalizedRmse = rmse / stressRange;
else
    normalizedRmse = NaN;
end
safeSse = max(sse, realmin("double"));
aic = n * log(safeSse / n) + 2 * parameterCount;
bic = n * log(safeSse / n) + parameterCount * log(n);

metrics.observationCount = n;
metrics.parameterCount = parameterCount;
metrics.sse = sse;
metrics.mse = mse;
metrics.rmse = rmse;
metrics.normalizedRmse = normalizedRmse;
metrics.mae = mae;
metrics.maxAbsoluteError = maxAbsoluteError;
metrics.rSquared = rSquared;
metrics.aic = aic;
metrics.bic = bic;
end
