function figureHandle = plotSelectedParameterPopulation(population)
%PLOTSELECTEDPARAMETERPOPULATION Plot fitted parameters by model and parameter.
arguments
    population (1,1) struct
end

data = population.parameterTable;
figureHandle = figure('Color','w');
if isempty(data)
    axesHandle = axes(figureHandle); %#ok<LAXES>
    text(axesHandle,0.5,0.5,'No selected-model parameters', ...
        'HorizontalAlignment','center');
    axis(axesHandle,'off');
    return;
end
labels = categorical(data.ModelName + ":" + data.Parameter);
scatter(labels, data.Value, 36, 'filled');
ylabel('Fitted parameter value');
title(sprintf('Selected-model parameters across %d specimens', ...
    population.specimenCount));
grid on;
box on;
end
