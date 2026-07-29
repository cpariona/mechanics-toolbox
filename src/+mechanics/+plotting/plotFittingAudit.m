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

modelNames = unique(summary.Model, "stable");
specimenIds = unique(summary.SpecimenId, "stable");
modelColors = lines(numel(modelNames));
lineStyles = ["-", "--", ":", "-."];
markers = ["o", "s", "^", "d", "v", ">", "<", "p", "h"];

for specimenIndex = 1:numel(specimenIds)
    specimenId = specimenIds(specimenIndex);
    lineStyle = lineStyles(1 + mod(specimenIndex - 1, numel(lineStyles)));
    marker = markers(1 + mod(specimenIndex - 1, numel(markers)));
    for modelIndex = 1:numel(modelNames)
        modelName = modelNames(modelIndex);
        seriesMask = summary.SpecimenId == specimenId & ...
            summary.Model == modelName;
        if ~any(seriesMask)
            continue;
        end
        series = sortrows(summary(seriesMask, :), "WindowFraction");
        plot(axesHandle, series.WindowFraction, series.InitialShearModulus, ...
            "LineStyle", lineStyle, "Marker", marker, ...
            "Color", modelColors(modelIndex, :), ...
            "LineWidth", 1.2, "MarkerSize", 5, ...
            "HandleVisibility", "off");
    end
end

plot(axesHandle, NaN, NaN, "Color", "none", ...
    "DisplayName", "Models");
for modelIndex = 1:numel(modelNames)
    plot(axesHandle, NaN, NaN, "-", ...
        "Color", modelColors(modelIndex, :), "LineWidth", 1.8, ...
        "DisplayName", char(modelNames(modelIndex)));
end
plot(axesHandle, NaN, NaN, "Color", "none", ...
    "DisplayName", "Specimens");
for specimenIndex = 1:numel(specimenIds)
    lineStyle = lineStyles(1 + mod(specimenIndex - 1, numel(lineStyles)));
    marker = markers(1 + mod(specimenIndex - 1, numel(markers)));
    plot(axesHandle, NaN, NaN, ...
        "LineStyle", lineStyle, "Marker", marker, "Color", [0 0 0], ...
        "LineWidth", 1.2, "MarkerSize", 5, ...
        "DisplayName", char(specimenIds(specimenIndex)));
end

xlabel(axesHandle, "Fitting window fraction");
ylabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
    "Equivalent initial shear modulus", stressUnit));
title(axesHandle, titleText + " — fitting-window audit", ...
    "Interpreter", "none");
windowMinimum = min(summary.WindowFraction);
windowMaximum = max(summary.WindowFraction);
windowPadding = max(0.02, 0.05 .* (windowMaximum - windowMinimum));
xlim(axesHandle, [max(0, windowMinimum - windowPadding), ...
    min(1.05, windowMaximum + windowPadding)]);
grid(axesHandle, "on");
box(axesHandle, "on");
legend(axesHandle, "Location", "best", "Interpreter", "none");
end
