function figureHandle = plotInitialShearModulusPopulation(population, stressUnit)
%PLOTINITIALSHEARMODULUSPOPULATION Plot derived initial shear modulus.
arguments
    population (1,1) struct
    stressUnit (1,1) string = ""
end

figureHandle = figure('Color','w','Position',[100 100 1050 760]);
if ~isfield(population,'initialShearModulus') || ...
        isempty(population.initialShearModulus.values)
    axesHandle = axes(figureHandle);
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
    model = mechanics.models.modelRegistry(data.ModelName(index));
    text(axesHandle, position(index), data.InitialShearModulus(index), ...
        "  " + model.displayName, 'Interpreter','none', ...
        'VerticalAlignment','middle');
end

centralStatistic = "median";
centralValue = NaN;
dispersionStatistic = "none";
dispersionValue = NaN;
if isfield(population.initialShearModulus, 'centralStatistic')
    centralStatistic = string(population.initialShearModulus.centralStatistic);
end
if isfield(population.initialShearModulus, 'centralValue')
    centralValue = double(population.initialShearModulus.centralValue);
elseif ~isempty(summary) && summary.SpecimenCount(1) > 0
    if centralStatistic == "mean"
        centralValue = summary.Mean(1);
    else
        centralValue = summary.Median(1);
    end
end
if isfield(population.initialShearModulus, 'dispersionStatistic')
    dispersionStatistic = string( ...
        population.initialShearModulus.dispersionStatistic);
    dispersionValue = double(population.initialShearModulus.dispersionValue);
end
if isfinite(centralValue)
    referenceLabel = localReferenceLabel(centralStatistic, centralValue, ...
        dispersionStatistic, dispersionValue, stressUnit);
    yline(axesHandle, centralValue, '--', referenceLabel, ...
        'Interpreter','latex', 'LabelHorizontalAlignment','left', ...
        'DisplayName', char(centralStatistic + " reference"));
end

axesHandle.XTick = position;
axesHandle.XTickLabel = cellstr(data.SpecimenId);
axesHandle.XTickLabelRotation = 45;
axesHandle.XLim = [0.5, height(data) + 0.75];
xlabel(axesHandle,'Specimen');
ylabel(axesHandle, mechanics.plotting.formatUnitLabel( ...
    'Initial shear modulus, \mu_0', stressUnit), 'Interpreter','tex');
title(axesHandle, 'Initial shear modulus by specimen');
grid(axesHandle,'on');
box(axesHandle,'on');
figureHandle.UserData.centralStatistic = centralStatistic;
figureHandle.UserData.referenceValue = centralValue;
figureHandle.UserData.dispersionStatistic = dispersionStatistic;
figureHandle.UserData.dispersionValue = dispersionValue;
figureHandle.UserData.annotationCount = double(isfinite(centralValue));
end

function label = localReferenceLabel(centralStatistic, centralValue, ...
        dispersionStatistic, dispersionValue, stressUnit)
if centralStatistic == "mean"
    symbol = "\bar{\mu}_0";
else
    symbol = "\mathrm{median}(\mu_0)";
end
unitText = "";
if strlength(stressUnit) > 0 && stressUnit ~= "-"
    unitText = "\,\mathrm{" + replace(stressUnit, " ", "\ ") + "}";
end
if dispersionStatistic == "standard-deviation" && isfinite(dispersionValue)
    label = sprintf('$%s = %.4g \\pm %.4g%s$', ...
        symbol, centralValue, dispersionValue, unitText);
else
    label = sprintf('$%s = %.4g%s$', symbol, centralValue, unitText);
end
end
