function figureHandle = plotFitUncertainty(fitResult, uncertainty)
%PLOTFITUNCERTAINTY Plot measured data, fitted model, and bootstrap band.
arguments
    fitResult (1,1) struct
    uncertainty (1,1) struct
end

x = uncertainty.predictionDeformation(:);
lower = uncertainty.predictionLower(:);
upper = uncertainty.predictionUpper(:);
medianPrediction = uncertainty.predictionMedian(:);

figureHandle = figure("Color", "w");
hold on;

fill([x; flipud(x)], [lower; flipud(upper)], ...
    [0.85, 0.85, 0.85], ...
    "EdgeColor", "none", ...
    "DisplayName", sprintf("%.0f%% bootstrap interval", ...
        100 * uncertainty.confidenceLevel));

plot(x, medianPrediction, "--", ...
    "LineWidth", 1.5, ...
    "DisplayName", "Bootstrap median");

plot(fitResult.deformation, fitResult.predictedStress, ...
    "LineWidth", 1.5, ...
    "DisplayName", "Best fit");

scatter(fitResult.deformation, fitResult.measuredStress, ...
    18, "filled", ...
    "DisplayName", "Measured data");

xlabel("Deformation");
ylabel("Stress");
title(sprintf("%s fit uncertainty", ...
    strrep(char(fitResult.modelName), "-", " ")));
legend("Location", "best");
grid on;
box on;
end
