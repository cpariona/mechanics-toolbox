function figureHandle = plotFitIdentifiability(diagnostics)
%PLOTFITIDENTIFIABILITY Plot parameter uncertainty and correlation.
arguments
    diagnostics (1,1) struct
end

summary = diagnostics.parameterSummary;
parameterNames = string(summary.Parameter);
parameterCount = height(summary);

figureHandle = figure("Color", "w");
tiledlayout(figureHandle, 1, 2, ...
    "TileSpacing", "compact", "Padding", "compact");

nexttile;
bar(categorical(parameterNames), summary.CoefficientOfVariation);
hold on;
yline(diagnostics.config.coefficientOfVariationThreshold, "--", ...
    "DisplayName", "Threshold");
ylabel("Coefficient of variation");
title("Parameter uncertainty");
grid on;
box on;

nexttile;
imagesc(diagnostics.correlationMatrix, [-1, 1]);
axis square;
colorbar;
xticks(1:parameterCount);
yticks(1:parameterCount);
xticklabels(parameterNames);
yticklabels(parameterNames);
title("Bootstrap parameter correlation");

for row = 1:parameterCount
    for column = 1:parameterCount
        value = diagnostics.correlationMatrix(row, column);
        if isfinite(value)
            text(column, row, sprintf("%.2f", value), ...
                "HorizontalAlignment", "center");
        end
    end
end
end
