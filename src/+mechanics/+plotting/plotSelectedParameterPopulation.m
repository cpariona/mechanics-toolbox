function figureHandle = plotSelectedParameterPopulation(population)
%PLOTSELECTEDPARAMETERPOPULATION Plot selected parameters by model family.
arguments
    population (1,1) struct
end

data = population.parameterTable;
figureHandle = figure('Color','w','Position',[100 100 1300 760]);
if isempty(data)
    figureHandle.UserData.parameterKeys = strings(0,1);
    axesHandle = axes(figureHandle); %#ok<LAXES>
    text(axesHandle,0.5,0.5,'No selected-model parameters', ...
        'HorizontalAlignment','center');
    axis(axesHandle,'off');
    return;
end

keys = unique(data.ModelName + "::" + data.Parameter, "stable");
figureHandle.UserData.parameterKeys = keys;
columnCount = min(3, numel(keys));
rowCount = ceil(numel(keys) / columnCount);
tiledlayout(figureHandle, rowCount, columnCount, ...
    'TileSpacing','compact','Padding','loose');

for index = 1:numel(keys)
    parts = split(keys(index), "::");
    modelName = parts(1);
    parameterName = parts(2);
    rows = data(data.ModelName == modelName & ...
        data.Parameter == parameterName, :);

    axesHandle = nexttile;
    axesHandle.Tag = 'parameter-data-axes';
    hold(axesHandle,'on');
    specimenPosition = (1:height(rows))';
    scatterHandle = scatter(axesHandle, specimenPosition, rows.Value, 36, ...
        'filled', 'DisplayName','Specimens');
    scatterHandle.Tag = 'parameter-data-series';

    summaryRows = population.overallSummary( ...
        population.overallSummary.ModelName == modelName & ...
        population.overallSummary.Parameter == parameterName, :);
    if ~isempty(summaryRows)
        yline(axesHandle, summaryRows.Median(1), '--', ...
            'Median', 'LabelHorizontalAlignment','left', ...
            'HandleVisibility','off');
    end

    axesHandle.XTick = specimenPosition;
    axesHandle.XTickLabel = cellstr(rows.SpecimenId);
    axesHandle.XTickLabelRotation = 35;
    axesHandle.XLim = [0.5 max(height(rows)+0.5,1.5)];
    xlabel(axesHandle,'Specimen');
    ylabel(axesHandle,'Fitted parameter value');
    title(axesHandle, modelName + " / " + parameterName, ...
        'Interpreter','none');
    grid(axesHandle,'on');
    box(axesHandle,'on');
end

sgtitle(figureHandle, sprintf( ...
    'Selected-model parameters across %d specimens', ...
    population.specimenCount), 'Interpreter','none','FontSize',18);
end
