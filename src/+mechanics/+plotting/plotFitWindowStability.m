function figureHandle = plotFitWindowStability(stability)
%PLOTFITWINDOWSTABILITY Plot fitted parameters across deformation windows.
arguments
    stability (1,1) struct
end

summary = stability.windowSummary;
valid = summary.Success;
parameterCount = numel(stability.parameterNames);

figureHandle = figure("Color", "w");
plot(summary.WindowFraction(valid), ...
    stability.parameterMatrix(valid, :), ...
    "-o", "LineWidth", 1.2);
xlabel("Maximum deformation-window fraction");
ylabel("Fitted parameter value");
title(sprintf("%s parameter stability", ...
    strrep(char(stability.modelName), "-", " ")));
legend(cellstr(stability.parameterNames), "Location", "best");
grid on;
box on;

if parameterCount == 0
    warning("mechanics:plotting:NoWindowStabilityParameters", ...
        "No parameters were available for plotting.");
end
end
