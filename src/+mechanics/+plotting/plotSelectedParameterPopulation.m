function figureHandle = plotSelectedParameterPopulation(population)
%PLOTSELECTEDPARAMETERPOPULATION Plot selected parameters by model family.
arguments
    population (1,1) struct
end

[data, summary, ~] = localNormalizePopulation(population);
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

    summaryRows = summary( ...
        summary.ModelName == modelName & ...
        summary.Parameter == parameterName, :);
    if ~isempty(summaryRows)
        [centralValue, centralLabel] = localCentralValue(summaryRows(1,:));
        if isfinite(centralValue)
            yline(axesHandle, centralValue, '--', centralLabel, ...
                'LabelHorizontalAlignment','left', ...
                'HandleVisibility','off');
        end
    end

    axesHandle.XTick = specimenPosition;
    axesHandle.XTickLabel = cellstr(rows.SpecimenId);
    axesHandle.XTickLabelRotation = 35;
    axesHandle.XLim = [0.5 max(height(rows)+0.5,1.5)];
    xlabel(axesHandle,'Specimen');
    ylabel(axesHandle,'Fitted parameter value');
    model = mechanics.models.modelRegistry(modelName);
    title(axesHandle, model.displayName + " / " + parameterName, ...
        'Interpreter','none');
    grid(axesHandle,'on');
    box(axesHandle,'on');
end

sgtitle(figureHandle, 'Selected-model parameters', ...
    'Interpreter','none','FontSize',18);
end

function [data, summary, specimenCount] = localNormalizePopulation(population)
if isfield(population, 'parameterTable')
    data = population.parameterTable;
    summary = population.overallSummary;
    if isfield(population, 'specimenCount')
        specimenCount = population.specimenCount;
    else
        specimenCount = numel(unique(data.SpecimenId));
    end
    return;
end

if ~isfield(population, 'values') || ~isfield(population, 'summary')
    error('mechanics:plotting:InvalidSelectedParameterPopulation', ...
        'Population requires parameterTable/overallSummary or values/summary.');
end

data = population.values;
if ismember('Model', string(data.Properties.VariableNames))
    data.Properties.VariableNames{'Model'} = 'ModelName';
end
summary = population.summary;
if ismember('Model', string(summary.Properties.VariableNames))
    summary.Properties.VariableNames{'Model'} = 'ModelName';
end
specimenCount = numel(unique(data.SpecimenId));
end

function [value, label] = localCentralValue(summaryRow)
names = string(summaryRow.Properties.VariableNames);
if ismember('Median', names)
    value = summaryRow.Median;
    label = 'Median';
elseif ismember('Mean', names)
    value = summaryRow.Mean;
    label = 'Mean';
else
    value = NaN;
    label = '';
end
end
