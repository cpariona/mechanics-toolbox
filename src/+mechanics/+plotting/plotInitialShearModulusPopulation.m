function figureHandle = plotInitialShearModulusPopulation(population)
%PLOTINITIALSHEARMODULUSPOPULATION Plot derived initial shear modulus.
arguments
    population (1,1) struct
end

figureHandle = figure('Color','w');
if ~isfield(population,'initialShearModulus') || ...
        isempty(population.initialShearModulus.values)
    axesHandle = axes(figureHandle); %#ok<LAXES>
    text(axesHandle,0.5,0.5,'No derived initial shear modulus values', ...
        'HorizontalAlignment','center');
    axis(axesHandle,'off');
    return;
end

data = population.initialShearModulus.values;
summary = population.initialShearModulus.summary;
axesHandle = axes(figureHandle);
hold(axesHandle,'on');
position = (1:height(data))';
scatter(axesHandle, position, data.InitialShearModulus, 42, 'filled', ...
    'DisplayName','Specimens');

for index = 1:height(data)
    text(axesHandle, position(index), data.InitialShearModulus(index), ...
        "  " + data.ModelName(index), 'Interpreter','none', ...
        'VerticalAlignment','middle');
end

if ~isempty(summary) && summary.SpecimenCount(1) > 0
    yline(axesHandle, summary.Median(1), '--', 'Median', ...
        'LabelHorizontalAlignment','left', 'DisplayName','Median');
end

axesHandle.XTick = position;
axesHandle.XTickLabel = cellstr(data.SpecimenId);
axesHandle.XTickLabelRotation = 45;
xlabel(axesHandle,'Specimen');
ylabel(axesHandle,'Initial shear modulus, \mu_0');
title(axesHandle, sprintf( ...
    'Derived initial shear modulus across %d specimens', ...
    population.initialShearModulus.specimenCount));
grid(axesHandle,'on');
box(axesHandle,'on');
end
