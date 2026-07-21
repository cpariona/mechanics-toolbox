function selection = selectBestModel(summary, config)
%SELECTBESTMODEL Select an eligible model using fit quality and parsimony.
arguments
    summary table
    config (1,1) struct = mechanics.config.modelSelectionConfig()
end

requiredVariables = [ ...
    "Model", "Eligible", "FullWindowRMSE", "FullWindowAIC", ...
    "FullWindowBIC", "MaximumRelativeParameterCV"];
if ~all(ismember(requiredVariables, string(summary.Properties.VariableNames)))
    error("mechanics:fitting:InvalidSelectionSummary", ...
        "The selection summary does not contain all required variables.");
end

eligibleRows = summary(summary.Eligible, :);
selection.hasEligibleModel = ~isempty(eligibleRows);
selection.bestModel = "";
selection.rankingMetric = upper(string(config.rankingMetric));
selection.rankedSummary = eligibleRows;
selection.reason = "";

if isempty(eligibleRows)
    selection.reason = "No model satisfied convergence and parameter-stability requirements.";
    return;
end

switch upper(string(config.rankingMetric))
    case "BIC"
        metricVariable = "FullWindowBIC";
    case "AIC"
        metricVariable = "FullWindowAIC";
    case "RMSE"
        metricVariable = "FullWindowRMSE";
    otherwise
        error("mechanics:fitting:UnknownRankingMetric", ...
            "Unknown model ranking metric: %s", config.rankingMetric);
end

bestRmse = min(eligibleRows.FullWindowRMSE);
rmseTolerance = max( ...
    config.rmseAbsoluteTolerance, ...
    abs(bestRmse) .* config.rmseRelativeTolerance);

practicallyEquivalent = ...
    eligibleRows.FullWindowRMSE <= bestRmse + rmseTolerance;
candidates = eligibleRows(practicallyEquivalent, :);

hasParameterCount = ismember( ...
    "FullWindowParameterCount", ...
    string(candidates.Properties.VariableNames));

if hasParameterCount
    candidates = sortrows(candidates, ...
        {'FullWindowParameterCount', ...
         char(metricVariable), ...
         'MaximumRelativeParameterCV', ...
         'FullWindowRMSE'}, ...
        {'ascend', 'ascend', 'ascend', 'ascend'});
else
    candidates = sortrows(candidates, ...
        {char(metricVariable), ...
         'MaximumRelativeParameterCV', ...
         'FullWindowRMSE'}, ...
        {'ascend', 'ascend', 'ascend'});
end

remainingRows = eligibleRows(~practicallyEquivalent, :);
remainingRows = sortrows(remainingRows, ...
    {char(metricVariable), 'MaximumRelativeParameterCV', 'FullWindowRMSE'}, ...
    {'ascend', 'ascend', 'ascend'});

eligibleRows = [candidates; remainingRows];

selection.rankedSummary = eligibleRows;
selection.bestModel = eligibleRows.Model(1);
selection.reason = sprintf( ...
    ['Models with full-window RMSE within %.6g of the minimum were ' ...
     'treated as practically equivalent; the most parsimonious stable ' ...
     'model was selected and %s was used as the secondary criterion.'], ...
    rmseTolerance, char(metricVariable));
end
