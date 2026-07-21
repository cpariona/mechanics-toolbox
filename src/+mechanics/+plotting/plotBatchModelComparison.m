function figureHandle = plotBatchModelComparison(batch)
%PLOTBATCHMODELCOMPARISON Plot model-selection frequencies.
arguments
    batch (1,1) struct
end

summary = batch.modelSummary;
figureHandle = figure('Color', 'w');
if isempty(summary)
    axesHandle = axes(figureHandle); %#ok<LAXES>
    text(axesHandle, 0.5, 0.5, 'No selected models', ...
        'HorizontalAlignment', 'center');
    axis(axesHandle, 'off');
    return;
end
bar(categorical(summary.ModelName), summary.SelectionFraction);
ylim([0, 1]);
ylabel('Selection fraction');
title(sprintf('Selected constitutive models across %d specimens', ...
    batch.selectedSpecimenCount));
grid on;
box on;
end
