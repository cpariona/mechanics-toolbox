function figureHandle = plotGroupMetricComparison(result)
%PLOTGROUPMETRICCOMPARISON Show specimen-level group metrics and mean differences.
if ~isfield(result, "groups") || numel(result.groups) ~= 2 || ...
        ~isfield(result, "metricComparison") || isempty(result.metricComparison)
    error("mechanics:plotting:NoPairwiseMetricComparison", ...
        "Metric plotting requires exactly two compared groups.");
end

metrics = string(result.metricComparison.Metric);
figureHandle = figure("Color", "w");
layout = tiledlayout(figureHandle, numel(metrics), 1, ...
    "TileSpacing", "compact", "Padding", "compact");

for metricIndex = 1:numel(metrics)
    metric = metrics(metricIndex);
    axesHandle = nexttile(layout);
    hold(axesHandle, "on")

    valuesA = localMetricValues(result.groups(1), metric);
    valuesB = localMetricValues(result.groups(2), metric);
    scatter(axesHandle, ones(size(valuesA)), valuesA, 36, "filled", ...
        "DisplayName", char(result.groups(1).name));
    scatter(axesHandle, 2 .* ones(size(valuesB)), valuesB, 36, "filled", ...
        "DisplayName", char(result.groups(2).name));

    row = result.metricComparison(metricIndex, :);
    plot(axesHandle, 1, row.MeanA, "d", ...
        "MarkerSize", 8, "LineWidth", 1.5, ...
        "DisplayName", "Group mean");
    plot(axesHandle, 2, row.MeanB, "d", ...
        "MarkerSize", 8, "LineWidth", 1.5, ...
        "HandleVisibility", "off");

    xlim(axesHandle, [0.5 2.5])
    xticks(axesHandle, [1 2])
    xticklabels(axesHandle, result.groupNames)
    ylabel(axesHandle, localMetricLabel(result, metric))
    title(axesHandle, localMetricTitle(metric), "Interpreter", "none")
    localDifferenceAnnotation(axesHandle, row, result, metric)
    grid(axesHandle, "on")
    box(axesHandle, "on")
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

function titleText = localMetricTitle(metric)
switch metric
    case "MaximumStrain"
        titleText = "Maximum strain";
    case "MaximumStress"
        titleText = "Maximum stress";
    case "MedianTangentModulus"
        titleText = "Median tangent modulus";
    otherwise
        titleText = metric;
end
end

function localDifferenceAnnotation(axesHandle, row, result, metric)
unit = localMetricUnit(result, metric);
unitText = "";
if strlength(unit) > 0
    unitText = " " + unit;
end

if all(isfinite([row.MeanDifference, row.ConfidenceLower, row.ConfidenceUpper]))
    annotation = sprintf( ...
        "Delta mean (A - B) = %.4g%s\n95%% CI [%.4g, %.4g]%s", ...
        row.MeanDifference, unitText, ...
        row.ConfidenceLower, row.ConfidenceUpper, unitText);
elseif isfinite(row.MeanDifference)
    annotation = sprintf("Delta mean (A - B) = %.4g%s", ...
        row.MeanDifference, unitText);
else
    return;
end

text(axesHandle, 0.98, 0.95, annotation, ...
    "Units", "normalized", ...
    "HorizontalAlignment", "right", ...
    "VerticalAlignment", "top", ...
    "BackgroundColor", "w", ...
    "Margin", 3, ...
    "Interpreter", "none");
end

function unit = localMetricUnit(result, metric)
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
        unit = mechanics.plotting.mechanicalDisplayUnit("deformation", strainUnit);
    case {"MaximumStress", "MedianTangentModulus"}
        unit = mechanics.plotting.mechanicalDisplayUnit("stress", stressUnit);
    otherwise
        unit = "";
end
end
