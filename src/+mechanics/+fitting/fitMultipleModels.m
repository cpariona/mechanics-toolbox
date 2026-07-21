function comparison = fitMultipleModels(modelNames, deformation, measuredStress, context, config)
%FITMULTIPLEMODELS Fit and compare several registered models.
arguments
    modelNames string
    deformation {mustBeNumeric, mustBeReal}
    measuredStress {mustBeNumeric, mustBeReal}
    context (1,1) struct = struct()
    config (1,1) struct = mechanics.config.fittingConfig()
end
modelNames = modelNames(:);
results = cell(numel(modelNames),1);
for i = 1:numel(modelNames)
    results{i} = mechanics.fitting.fitModel( ...
        modelNames(i), deformation, measuredStress, context, config);
end

names = strings(numel(results),1);
parameterCount = zeros(numel(results),1);
rmse = zeros(numel(results),1);
rSquared = zeros(numel(results),1);
aic = zeros(numel(results),1);
bic = zeros(numel(results),1);
converged = false(numel(results),1);
for i = 1:numel(results)
    names(i) = results{i}.modelName;
    parameterCount(i) = results{i}.metrics.parameterCount;
    rmse(i) = results{i}.metrics.rmse;
    rSquared(i) = results{i}.metrics.rSquared;
    aic(i) = results{i}.metrics.aic;
    bic(i) = results{i}.metrics.bic;
    converged(i) = results{i}.converged;
end
summary = table(names, parameterCount, rmse, rSquared, aic, bic, converged, ...
    'VariableNames', {'Model','ParameterCount','RMSE','RSquared','AIC','BIC','Converged'});
summary = sortrows(summary, {'BIC','RMSE'}, {'ascend','ascend'});
comparison.results = results;
comparison.summary = summary;
comparison.bestModelByBIC = summary.Model(1);
end
