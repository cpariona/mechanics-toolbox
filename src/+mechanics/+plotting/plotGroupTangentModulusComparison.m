function figureHandle = plotGroupTangentModulusComparison(result)
%PLOTGROUPTANGENTMODULUSCOMPARISON Compare tangent-modulus populations.
if ~isfield(result, "groups") || numel(result.groups) ~= 2
    error("mechanics:plotting:NoPairwiseComparison", ...
        "Tangent-modulus plotting requires exactly two groups.");
end

for index = 1:2
    population = result.groups(index).population;
    if ~isfield(population, "tangentModulusStatus") || ...
            population.tangentModulusStatus ~= "completed"
        error("mechanics:plotting:MissingGroupTangentModulus", ...
            "Both groups require completed tangent-modulus populations.");
    end
end

stressUnit = localStressUnit(result);
figureHandle = figure("Color", "w");
axesHandle = axes(figureHandle);
hold(axesHandle, "on")
groupColors = nan(2, 3);

for index = 1:2
    group = result.groups(index);
    tangent = group.population.tangentModulus;
    lineHandle = plot(axesHandle, tangent.strain, tangent.centralModulus, ...
        "LineWidth", 2, ...
        "DisplayName", char(group.name));
    groupColors(index, :) = lineHandle.Color;
    localConfidenceBand(axesHandle, tangent, lineHandle.Color);
    uistack(lineHandle, "top")
end

if isfield(result, "modelInitialShearSummary") && ...
        ~isempty(result.modelInitialShearSummary)
    shearSummary = result.modelInitialShearSummary;
    for index = 1:height(shearSummary)
        value = shearSummary.InitialShearModulus(index);
        if ~isfinite(value)
            continue;
        end
        label = sprintf("mu0 model reference — %s", shearSummary.Group(index));
        lineArguments = {"--", "LineWidth", 1.2, "DisplayName", label};
        if index <= size(groupColors, 1) && all(isfinite(groupColors(index, :)))
            lineArguments = [lineArguments, {"Color", groupColors(index, :)}]; %#ok<AGROW>
        end
        yline(axesHandle, value, lineArguments{:});
    end
end

xlabel(axesHandle, localStrainLabel(result))
ylabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
    "Tangent modulus", mechanics.plotting.mechanicalDisplayUnit( ...
    "stress", stressUnit)))
title(axesHandle, ...
    "Tangent-modulus populations with model-derived initial shear references")
grid(axesHandle, "on")
box(axesHandle, "on")
legend(axesHandle, "Location", "best", "Interpreter", "none")

figureHandle.UserData = struct( ...
    "initialShearSummary", localInitialShearUserData(result));
end

function localConfidenceBand(axesHandle, tangent, faceColor)
if ~isfield(tangent, "confidenceLower") || ...
        ~isfield(tangent, "confidenceUpper") || ...
        ~all(isfinite(tangent.confidenceLower)) || ...
        ~all(isfinite(tangent.confidenceUpper))
    return;
end
fill(axesHandle, ...
    [tangent.strain; flipud(tangent.strain)], ...
    [tangent.confidenceLower; flipud(tangent.confidenceUpper)], ...
    faceColor, ...
    "EdgeColor", "none", ...
    "FaceAlpha", 0.15, ...
    "HandleVisibility", "off");
end

function label = localStrainLabel(result)
strainMeasure = "";
strainUnit = "";
if isfield(result, "mechanics")
    if isfield(result.mechanics, "strainMeasure")
        strainMeasure = lower(string(result.mechanics.strainMeasure));
    end
    if isfield(result.mechanics, "strainUnit")
        strainUnit = string(result.mechanics.strainUnit);
    end
end
switch strainMeasure
    case {"engineering", "engineering-strain"}
        strainMeasure = "engineering-strain";
    case {"true", "true-strain"}
        strainMeasure = "true-strain";
    otherwise
        strainMeasure = "";
end
label = mechanics.plotting.mechanicalAxisLabel( ...
    "deformation", strainMeasure, strainUnit);
end

function unit = localStressUnit(result)
unit = "";
if isfield(result, "mechanics") && isfield(result.mechanics, "stressUnit")
    unit = string(result.mechanics.stressUnit);
end
end

function data = localInitialShearUserData(result)
data = table();
if isfield(result, "modelInitialShearSummary")
    data = result.modelInitialShearSummary;
end
end
