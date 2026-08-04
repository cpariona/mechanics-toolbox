function figureHandle = plotTensileApplicationRangeSensitivity(result)
%PLOTTENSILEAPPLICATIONRANGESENSITIVITY Plot mu0 and objective by upper limit.
arguments
    result (1,1) struct
end
if ~isfield(result, "rangeSensitivity") || ...
        ~isfield(result.rangeSensitivity, "scenarioSummary")
    error("mechanics:plotting:InvalidTensileApplicationRangeSensitivity", ...
        "Provide a completed range-sensitivity result.");
end
summary = result.rangeSensitivity.scenarioSummary;
required = ["MaximumDeformation", "Status", "SelectedModelName", ...
    "Objective", "Mu0"];
if ~all(ismember(required, string(summary.Properties.VariableNames)))
    error("mechanics:plotting:IncompleteTensileApplicationRangeSensitivity", ...
        "Sensitivity summary is missing required variables.");
end
mask = string(summary.Status) == "completed";
if ~any(mask)
    error("mechanics:plotting:NoCompletedTensileApplicationRangeScenario", ...
        "No completed sensitivity scenario is available for plotting.");
end
summary = summary(mask,:);
maximums = summary.MaximumDeformation;
modelNames = string(summary.SelectedModelName);
specimens = result.selectedFit.specimens;
stressUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "stress", string(specimens(1).StressUnit));
strainUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "deformation", string(specimens(1).StrainUnit));

figureHandle = figure("Color", "w");
layout = tiledlayout(figureHandle, 2, 1, ...
    "TileSpacing", "loose", "Padding", "compact");
muAxes = nexttile(layout, 1);
plot(muAxes, maximums, summary.Mu0, "-o", ...
    "LineWidth", 1.5, "MarkerSize", 6);
xlabel(muAxes, "Upper engineering-strain limit [" + strainUnit + "]");
ylabel(muAxes, "\mu_0 [" + stressUnit + "]", ...
    "Interpreter", "tex");
if numel(unique(modelNames)) == 1
    title(muAxes, "Reference shear-modulus sensitivity (" + ...
        modelNames(1) + ")", "Interpreter", "none");
else
    title(muAxes, "Reference shear-modulus sensitivity");
    for index = 1:height(summary)
        text(muAxes, maximums(index), summary.Mu0(index), ...
            "  " + modelNames(index), "Interpreter", "none", ...
            "VerticalAlignment", "bottom", ...
            "HorizontalAlignment", "left");
    end
end
grid(muAxes, "on"); box(muAxes, "on");

objectiveAxes = nexttile(layout, 2);
plot(objectiveAxes, maximums, summary.Objective, "-o", ...
    "LineWidth", 1.5, "MarkerSize", 6);
xlabel(objectiveAxes, "Upper engineering-strain limit [" + strainUnit + "]");
ylabel(objectiveAxes, mechanics.plotting.mechanicalAxisLabel( ...
    "objective", "", "-"));
title(objectiveAxes, "Fit objective sensitivity");
grid(objectiveAxes, "on"); box(objectiveAxes, "on");
end
