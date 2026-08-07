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

nexttile
hold on
plot(comparison.strain, comparison.meanStressA, ...
    "LineWidth", 2, "DisplayName", char(comparison.groupNameA));
plot(comparison.strain, comparison.meanStressB, ...
    "LineWidth", 2, "DisplayName", char(comparison.groupNameB));
xlabel(strainLabel)
ylabel(stressLabel)
grid on
box on
legend("Location", "best", "Interpreter", "none")

nexttile
hold on
if all(isfinite(comparison.confidenceLower)) && ...
        all(isfinite(comparison.confidenceUpper))
    fill([comparison.strain; flipud(comparison.strain)], ...
        [comparison.confidenceLower; flipud(comparison.confidenceUpper)], ...
        0.8 * [1 1 1], ...
        "EdgeColor", "none", ...
        "FaceAlpha", 0.5, ...
        "DisplayName", "Bootstrap 95% CI");
end

if isCompression
    differenceLabel = sprintf("|%s| - |%s|", ...
        comparison.groupNameB, comparison.groupNameA);
    plot(comparison.strain, comparison.meanDifference, ...
        "LineWidth", 2, "DisplayName", differenceLabel);
    title(sprintf("Positive values indicate larger compressive-stress magnitude for %s", ...
        comparison.groupNameB), "Interpreter", "none")
    differenceConvention = "compression-magnitude-B-minus-A";
else
    plot(comparison.strain, comparison.meanDifference, ...
        "LineWidth", 2, "DisplayName", "Mean difference A - B");
    differenceConvention = "signed-A-minus-B";
end

yline(0, "--", "HandleVisibility", "off")
xlabel(strainLabel)
ylabel(stressDifferenceLabel)
grid on
box on
legend("Location", "best", "Interpreter", "none")

figureHandle.UserData.differenceConvention = differenceConvention;
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
