function figureHandle = plotGroupComparison(result)
%PLOTGROUPCOMPARISON Plot group means and pairwise difference.
if ~isfield(result, "curveComparison") || ...
        isempty(fieldnames(result.curveComparison))
    error("mechanics:plotting:NoPairwiseComparison", ...
        "Pairwise plotting requires exactly two groups.");
end

comparison = result.curveComparison;
[strainLabel, stressLabel, stressDifferenceLabel] = localAxisLabels(result);
isCompression = isfield(result, "testType") && ...
    lower(string(result.testType)) == "compression";

figureHandle = figure("Color", "w");
tiledlayout(figureHandle, 2, 1);

upperAxes = nexttile;
hold(upperAxes, "on")
lineA = plot(upperAxes, comparison.strain, comparison.meanStressA, ...
    "LineWidth", 2, "DisplayName", char(comparison.groupNameA));
localConfidenceBand(upperAxes, comparison.strain, ...
    comparison.confidenceLowerA, comparison.confidenceUpperA, lineA.Color);
uistack(lineA, "top")
lineB = plot(upperAxes, comparison.strain, comparison.meanStressB, ...
    "LineWidth", 2, "DisplayName", char(comparison.groupNameB));
localConfidenceBand(upperAxes, comparison.strain, ...
    comparison.confidenceLowerB, comparison.confidenceUpperB, lineB.Color);
uistack(lineB, "top")
xlabel(upperAxes, strainLabel)
ylabel(upperAxes, stressLabel)
title(upperAxes, "Mean stress with 95% bootstrap confidence bands")
grid(upperAxes, "on")
box(upperAxes, "on")
legend(upperAxes, "Location", "best", "Interpreter", "none")

lowerAxes = nexttile;
hold(lowerAxes, "on")
if all(isfinite(comparison.confidenceLower)) && ...
        all(isfinite(comparison.confidenceUpper))
    fill(lowerAxes, ...
        [comparison.strain; flipud(comparison.strain)], ...
        [comparison.confidenceLower; flipud(comparison.confidenceUpper)], ...
        0.8 * [1 1 1], ...
        "EdgeColor", "none", ...
        "FaceAlpha", 0.5, ...
        "DisplayName", "Bootstrap 95% CI");
end

if isCompression
    differenceLabel = sprintf("|%s| - |%s|", ...
        comparison.groupNameB, comparison.groupNameA);
    plot(lowerAxes, comparison.strain, comparison.meanDifference, ...
        "LineWidth", 2, "DisplayName", differenceLabel);
    title(lowerAxes, sprintf( ...
        "Positive values indicate larger compressive-stress magnitude for %s", ...
        comparison.groupNameB), "Interpreter", "none")
    differenceConvention = "compression-magnitude-B-minus-A";
else
    plot(lowerAxes, comparison.strain, comparison.meanDifference, ...
        "LineWidth", 2, "DisplayName", "Mean difference A - B");
    differenceConvention = "signed-A-minus-B";
end

yline(lowerAxes, 0, "--", "HandleVisibility", "off")
xlabel(lowerAxes, strainLabel)
ylabel(lowerAxes, stressDifferenceLabel)
grid(lowerAxes, "on")
box(lowerAxes, "on")
legend(lowerAxes, "Location", "best", "Interpreter", "none")

figureHandle.UserData = struct( ...
    "differenceConvention", differenceConvention, ...
    "groupCurveConfidenceBands", localGroupBandsAvailable(comparison));
end

function localConfidenceBand(axesHandle, strain, lower, upper, faceColor)
if isempty(lower) || isempty(upper) || ...
        ~all(isfinite(lower)) || ~all(isfinite(upper))
    return;
end
fill(axesHandle, ...
    [strain; flipud(strain)], ...
    [lower; flipud(upper)], ...
    faceColor, ...
    "EdgeColor", "none", ...
    "FaceAlpha", 0.15, ...
    "HandleVisibility", "off");
end

function available = localGroupBandsAvailable(comparison)
fields = ["confidenceLowerA","confidenceUpperA", ...
    "confidenceLowerB","confidenceUpperB"];
available = all(isfield(comparison, cellstr(fields)));
if ~available
    return;
end
for index = 1:numel(fields)
    available = available && all(isfinite(comparison.(fields(index))));
end
end

function [strainLabel, stressLabel, differenceLabel] = localAxisLabels(result)
strainMeasure = "";
stressMeasure = "";
strainUnit = "";
stressUnit = "";
if isfield(result, "mechanics")
    mechanicsMetadata = result.mechanics;
    if isfield(mechanicsMetadata, "strainMeasure")
        strainMeasure = localStrainMeasure(mechanicsMetadata.strainMeasure);
    end
    if isfield(mechanicsMetadata, "stressMeasure")
        stressMeasure = localStressMeasure(mechanicsMetadata.stressMeasure);
    end
    if isfield(mechanicsMetadata, "strainUnit")
        strainUnit = string(mechanicsMetadata.strainUnit);
    end
    if isfield(mechanicsMetadata, "stressUnit")
        stressUnit = string(mechanicsMetadata.stressUnit);
    end
end

strainLabel = mechanics.plotting.mechanicalAxisLabel( ...
    "deformation", strainMeasure, strainUnit);
stressLabel = mechanics.plotting.mechanicalAxisLabel( ...
    "stress", stressMeasure, stressUnit);

if isfield(result, "testType") && lower(string(result.testType)) == "compression"
    differenceLabel = mechanics.plotting.formatUnitLabel( ...
        "Compressive stress magnitude difference", ...
        mechanics.plotting.mechanicalDisplayUnit("stress", stressUnit));
else
    differenceLabel = mechanics.plotting.formatUnitLabel( ...
        "Stress difference", ...
        mechanics.plotting.mechanicalDisplayUnit("stress", stressUnit));
end
end

function measure = localStrainMeasure(measure)
measure = lower(string(measure));
switch measure
    case {"engineering", "engineering-strain"}
        measure = "engineering-strain";
    case {"true", "true-strain"}
        measure = "true-strain";
    otherwise
        measure = "";
end
end

function measure = localStressMeasure(measure)
measure = lower(string(measure));
switch measure
    case {"engineering", "nominal"}
        measure = "nominal";
    case {"true", "cauchy"}
        measure = "cauchy";
    otherwise
        measure = "";
end
end
