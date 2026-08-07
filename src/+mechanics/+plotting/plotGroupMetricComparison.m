function figureHandle = plotGroupMetricComparison(result)
%PLOTGROUPMETRICCOMPARISON Show specimen-level group metrics and mean differences.
if ~isfield(result, "groups") || numel(result.groups) ~= 2 || ...
        ~isfield(result, "metricComparison") || isempty(result.metricComparison)
    error("mechanics:plotting:NoPairwiseMetricComparison", ...
        "Metric plotting requires exactly two compared groups.");
end

metrics = string(result.metricComparison.Metric);
figureHandle = figure("Color", "w");
tiledlayout(figureHandle, numel(metrics), 1);

for metricIndex = 1:numel(metrics)
    metric = metrics(metricIndex);
    nexttile
    hold on

    valuesA = localMetricValues(result.groups(1), metric);
    valuesB = localMetricValues(result.groups(2), metric);
    scatter(ones(size(valuesA)), valuesA, 36, "filled", ...
        "DisplayName", char(result.groups(1).name));
    scatter(2 .* ones(size(valuesB)), valuesB, 36, "filled", ...
        "DisplayName", char(result.groups(2).name));

    row = result.metricComparison(metricIndex, :);
    plot(1, row.MeanA, "d", "MarkerSize", 8, "LineWidth", 1.5, ...
        "DisplayName", "Group mean");
    plot(2, row.MeanB, "d", "MarkerSize", 8, "LineWidth", 1.5, ...
        "HandleVisibility", "off");

    xlim([0.5 2.5])
    xticks([1 2])
    xticklabels(result.groupNames)
    ylabel(localMetricLabel(result, metric))
    title(localDifferenceTitle(row, metric), "Interpreter", "none")
    grid on
    box on
end
end

function values = localMetricValues(group, metric)
if ~ismember(metric, string(group.summary.Properties.VariableNames))
    values = zeros(0, 1);
    return;
end
values = group.summary.(metric);
values = values(isfinite(values));
end

function label = localMetricLabel(result, metric)
strainUnit = "";
stressUnit = "";
if isfield(result, "mechanics")
    if isfield(result.mechanics, "strainUnit")
        strainUnit = string(result.mechanics.strainUnit);
    end
    if isfield(result.mechanics, "stressUnit")
        stressUnit = string(result.mechanics.stressUnit);
    end
end

switch metric
    case "MaximumStrain"
        label = mechanics.plotting.formatUnitLabel( ...
            "Maximum strain", mechanics.plotting.mechanicalDisplayUnit( ...
            "deformation", strainUnit));
    case "MaximumStress"
        label = mechanics.plotting.formatUnitLabel( ...
            "Maximum stress", mechanics.plotting.mechanicalDisplayUnit( ...
            "stress", stressUnit));
    case "MedianTangentModulus"
        label = mechanics.plotting.formatUnitLabel( ...
            "Median tangent modulus", mechanics.plotting.mechanicalDisplayUnit( ...
            "stress", stressUnit));
    otherwise
        label = metric;
end
end

function titleText = localDifferenceTitle(row, metric)
if all(isfinite([row.MeanDifference, row.ConfidenceLower, row.ConfidenceUpper]))
    titleText = sprintf( ...
        "%s: mean A - B = %.4g, bootstrap 95%% CI [%.4g, %.4g]", ...
        metric, row.MeanDifference, row.ConfidenceLower, row.ConfidenceUpper);
elseif isfinite(row.MeanDifference)
    titleText = sprintf("%s: mean A - B = %.4g", metric, row.MeanDifference);
else
    titleText = metric;
end
end
