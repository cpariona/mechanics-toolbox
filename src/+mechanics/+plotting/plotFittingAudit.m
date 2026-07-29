function figureHandle = plotFittingAudit(audit, titleText, stressUnit)
%PLOTFITTINGAUDIT Plot initial shear modulus across fitting windows.
arguments
    audit (1,1) struct
    titleText (1,1) string = "Mechanical study"
    stressUnit (1,1) string = "-"
end

figureHandle = gobjects(0);
if ~isfield(audit, "windowSummary") || isempty(audit.windowSummary)
    return;
end

summary = audit.windowSummary;
mask = summary.Succeeded & isfinite(summary.InitialShearModulus);
summary = summary(mask, :);
if isempty(summary)
    return;
end

figureHandle = figure("Visible", "off", "Color", "w", ...
    "Position", [100 100 1050 760]);
axesHandle = axes(figureHandle);
hold(axesHandle, "on");
seriesNames = unique(summary.SpecimenId + " — " + summary.Model, "stable");
for index = 1:numel(seriesNames)
    seriesMask = summary.SpecimenId + " — " + summary.Model == seriesNames(index);
    series = sortrows(summary(seriesMask, :), "WindowFraction");
    plot(axesHandle, series.WindowFraction, series.InitialShearModulus, ...
        "-o", "LineWidth", 1.1, "MarkerSize", 5, ...
        "DisplayName", char(seriesNames(index)));
end
xlabel(axesHandle, "Fitting window fraction");
ylabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
    "Equivalent initial shear modulus", stressUnit));
title(axesHandle, titleText + " — fitting-window audit", ...
    "Interpreter", "none");
xlim(axesHandle, [0, 1.05]);
grid(axesHandle, "on");
box(axesHandle, "on");
legend(axesHandle, "Location", "best", "Interpreter", "none");
end
