function figureHandle = plotGroupParameterInference(inference)
%PLOTGROUPPARAMETERINFERENCE Plot mean differences and confidence intervals.
arguments
    inference (1,1) struct
end
summary = inference.comparisonTable;
valid = isfinite(summary.MeanDifference);
summary = summary(valid,:);
figureHandle = figure('Color','w');
if isempty(summary)
    axesHandle = axes(figureHandle); %#ok<LAXES>
    text(axesHandle, 0.5, 0.5, 'No successful group comparisons', ...
        'HorizontalAlignment','center');
    axis(axesHandle,'off');
    return;
end
labels = summary.ModelName + ":" + summary.Parameter + " " + ...
    summary.Group1 + "-" + summary.Group2;
y = (1:height(summary))';
errorbar(summary.MeanDifference, y, ...
    summary.MeanDifference-summary.ConfidenceIntervalLower, ...
    summary.ConfidenceIntervalUpper-summary.MeanDifference, ...
    'horizontal', 'o');
yticks(y);
yticksValues = cellstr(labels);
yticklabels(yticksValues);
ylim([0.5, height(summary)+0.5]);
xline(0,'--');
xlabel('Mean difference (Group 1 - Group 2)');
title('Selected-parameter group comparisons');
grid on;
box on;
end
