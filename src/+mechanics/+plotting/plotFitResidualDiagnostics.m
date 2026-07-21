function figureHandle = plotFitResidualDiagnostics(diagnostics)
%PLOTFITRESIDUALDIAGNOSTICS Plot residual structure and outliers.
arguments
    diagnostics (1,1) struct
end

figureHandle = figure("Color", "w");
tiledlayout(figureHandle, 2, 2, ...
    "TileSpacing", "compact", "Padding", "compact");

nexttile;
scatter(diagnostics.deformation, diagnostics.residual, 18, "filled");
yline(0, "--");
xlabel("Deformation");
ylabel("Residual");
title("Residual versus deformation");
grid on;
box on;

nexttile;
scatter(diagnostics.predictedStress, abs(diagnostics.residual), 18, "filled");
xlabel("Predicted stress");
ylabel("Absolute residual");
title("Residual magnitude versus prediction");
grid on;
box on;

nexttile;
plot(diagnostics.standardizedResidual, "LineWidth", 1.2);
hold on;
yline(diagnostics.config.standardizedResidualThreshold, "--");
yline(-diagnostics.config.standardizedResidualThreshold, "--");
xlabel("Observation index");
ylabel("Standardized residual");
title("Standardized residual sequence");
grid on;
box on;

nexttile;
if any(diagnostics.outlierMask)
    scatter(diagnostics.deformation(~diagnostics.outlierMask), ...
        diagnostics.measuredStress(~diagnostics.outlierMask), 18, "filled");
    hold on;
    scatter(diagnostics.deformation(diagnostics.outlierMask), ...
        diagnostics.measuredStress(diagnostics.outlierMask), 30, "x");
else
    scatter(diagnostics.deformation, diagnostics.measuredStress, 18, "filled");
    hold on;
end
plot(diagnostics.deformation, diagnostics.predictedStress, ...
    "LineWidth", 1.5);
xlabel("Deformation");
ylabel("Stress");
title("Fit and flagged observations");
grid on;
box on;
end
