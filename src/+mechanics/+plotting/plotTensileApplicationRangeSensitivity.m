function figureHandle = plotTensileApplicationRangeSensitivity(result)
%PLOTTENSILEAPPLICATIONRANGESENSITIVITY Plot mu0 and objective by upper limit.
arguments
    result (1,1) struct
end
if ~isfield(result, "rangeSensitivity") || ~isfield(result.rangeSensitivity, "scenarioSummary")
    error("mechanics:plotting:InvalidTensileApplicationRangeSensitivity", "Provide a completed range-sensitivity result.");
end
summary = result.rangeSensitivity.scenarioSummary;
required = ["MaximumDeformation", "Status", "SelectedModelName", "Objective", "Mu0"];
if ~all(ismember(required, string(summary.Properties.VariableNames)))
    error("mechanics:plotting:IncompleteTensileApplicationRangeSensitivity", "Sensitivity summary is missing required variables.");
end
mask = string(summary.Status) == "completed";
if ~any(mask)
    error("mechanics:plotting:NoCompletedTensileApplicationRangeScenario", "No completed sensitivity scenario is available for plotting.");
end
summary = summary(mask,:);
maximums = summary.MaximumDeformation;
modelNames = string(summary.SelectedModelName);
specimens = result.selectedFit.specimens;
stressUnit = string(specimens(1).StressUnit);
strainUnit = string(specimens(1).StrainUnit);
figureHandle = figure("Color", "w");
layout = tiledlayout(figureHandle, 2, 1, "TileSpacing", "compact", "Padding", "compact");
muAxes = nexttile(layout, 1);
plot(muAxes, maximums, summary.Mu0, "-o", "LineWidth", 1.5, "MarkerSize", 6);
xlabel(muAxes, localMaximumLabel(strainUnit));
ylabel(muAxes, localMuLabel(stressUnit));
title(muAxes, "Reference shear-modulus sensitivity");
grid(muAxes, "on"); box(muAxes, "on");
for index = 1:height(summary)
    text(muAxes, maximums(index), summary.Mu0(index), "  " + modelNames(index), "Interpreter", "none", "VerticalAlignment", "bottom");
end
objectiveAxes = nexttile(layout, 2);
plot(objectiveAxes, maximums, summary.Objective, "-o", "LineWidth", 1.5, "MarkerSize", 6);
xlabel(objectiveAxes, localMaximumLabel(strainUnit));
ylabel(objectiveAxes, "Normalized objective [1]");
title(objectiveAxes, "Fit objective sensitivity");
grid(objectiveAxes, "on"); box(objectiveAxes, "on");
end

function label = localMaximumLabel(unit)
label = "Upper engineering-strain limit";
if strlength(unit) > 0
    label = label + " [" + unit + "]";
end
end

function label = localMuLabel(unit)
label = "Reference shear modulus, mu0";
if strlength(unit) > 0
    label = label + " [" + unit + "]";
end
end
