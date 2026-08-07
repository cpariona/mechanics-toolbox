function figureHandle = plotJointModeFit(result, modeName)
%PLOTJOINTMODEFIT Plot measured specimens, population median, and joint fit.
arguments
    result (1,1) struct
    modeName (1,1) string
end

required = ["selectedModelName","selectedFit"];
if ~all(isfield(result, required)) || ...
        ~all(isfield(result.selectedFit, ...
        ["specimens","parameterNames","parameters"]))
    error("mechanics:plotting:InvalidJointCharacterizationResult", ...
        "Provide a completed joint material-characterization result.");
end

parameterNames = string(result.selectedFit.parameterNames(:));
parameters = result.selectedFit.parameters(:);
if numel(parameterNames) ~= numel(parameters)
    error("mechanics:plotting:InvalidJointParameterSummary", ...
        "Selected parameter names and values must have matching lengths.");
end

model = mechanics.models.modelRegistry(string(result.selectedModelName));
derivedNames = string(model.derivedQuantityNames(:));
derivedValues = localDerivedValues(model, parameters);

modeName = lower(strtrim(modeName));
specimens = result.selectedFit.specimens;
mask = string({specimens.Mode})' == modeName;
if ~any(mask)
    error("mechanics:plotting:UnknownJointMode", ...
        "No selected-fit specimens exist for mode %s.", modeName);
end

indices = find(mask);
modeSpecimens = specimens(indices);
localValidateModeContexts(modeSpecimens, modeName);

figureHandle = figure("Color", "w");
axesHandle = axes(figureHandle);
hold(axesHandle, "on")
colors = lines(numel(modeSpecimens));
for index = 1:numel(modeSpecimens)
    specimen = modeSpecimens(index);
    plot(axesHandle, specimen.Deformation, specimen.MeasuredStress, "-", ...
        "LineWidth", 0.8, "Color", colors(index, :), ...
        "DisplayName", specimen.OriginalSpecimenId + " measured");
end

[populationDeformation, populationMedian] = ...
    localPopulationMedian(modeSpecimens, 400);
plot(axesHandle, populationDeformation, populationMedian, "-", ...
    "Color", [0.35, 0.35, 0.35], "LineWidth", 2.2, ...
    "DisplayName", "Population median");

minimumDeformation = min(arrayfun(@(item) min(item.Deformation), modeSpecimens));
maximumDeformation = max(arrayfun(@(item) max(item.Deformation), modeSpecimens));
referenceDeformation = linspace(minimumDeformation, maximumDeformation, 600)';
referenceStress = mechanics.models.evaluateModel( ...
    model.name, referenceDeformation, parameters, ...
    modeSpecimens(1).Context);
plot(axesHandle, referenceDeformation, referenceStress, "k--", ...
    "LineWidth", 1.8, ...
    "DisplayName", "Joint selected fit (" + model.displayName + ")");

xlabel(axesHandle, mechanics.plotting.mechanicalAxisLabel( ...
    "deformation", modeSpecimens(1).Context.deformationMeasure, ...
    modeSpecimens(1).StrainUnit))
ylabel(axesHandle, mechanics.plotting.mechanicalAxisLabel( ...
    "stress", modeSpecimens(1).Context.stressMeasure, ...
    modeSpecimens(1).StressUnit))
title(axesHandle, "Joint material characterization: " + modeName + ...
    " (" + model.displayName + ")")
if modeName == "compression"
    legendLocation = "southeast";
    textPosition = [0.03, 0.97];
    horizontalAlignment = "left";
else
    legendLocation = "northwest";
    textPosition = [0.97, 0.04];
    horizontalAlignment = "right";
end
legend(axesHandle, "Location", legendLocation, "Interpreter", "none")
text(axesHandle, textPosition(1), textPosition(2), ...
    localParameterText(parameterNames, parameters, derivedNames, ...
    derivedValues, modeSpecimens(1).StressUnit), ...
    "Units", "normalized", ...
    "HorizontalAlignment", horizontalAlignment, ...
    "VerticalAlignment", localVerticalAlignment(modeName), ...
    "Interpreter", "tex", "BackgroundColor", "w", ...
    "EdgeColor", [0.4, 0.4, 0.4], "Margin", 5, "FontSize", 9);
grid(axesHandle, "on")
box(axesHandle, "on")
hold(axesHandle, "off")
end

function values = localDerivedValues(model, parameters)
if isempty(model.evaluateDerivedQuantities)
    values = zeros(0, 1);
    return
end
values = model.evaluateDerivedQuantities(parameters);
values = values(:);
if numel(values) ~= numel(model.derivedQuantityNames)
    error("mechanics:plotting:InvalidDerivedQuantitySummary", ...
        "Derived quantity names and values must have matching lengths.");
end
end

function [commonDeformation, populationMedian] = ...
        localPopulationMedian(specimens, pointCount)
minimumCommon = max(arrayfun(@(item) min(item.Deformation), specimens));
maximumCommon = min(arrayfun(@(item) max(item.Deformation), specimens));
if minimumCommon >= maximumCommon
    error("mechanics:plotting:NoCommonJointModeDomain", ...
        "Joint-mode specimens do not share a deformation interval.");
end
commonDeformation = linspace(minimumCommon, maximumCommon, pointCount)';
interpolatedStress = nan(pointCount, numel(specimens));
for index = 1:numel(specimens)
    deformation = specimens(index).Deformation(:);
    stress = specimens(index).MeasuredStress(:);
    [deformation, order] = sort(deformation);
    stress = stress(order);
    [deformation, uniqueIndices] = unique(deformation, "stable");
    stress = stress(uniqueIndices);
    interpolatedStress(:, index) = interp1( ...
        deformation, stress, commonDeformation, "linear");
end
if any(~isfinite(interpolatedStress), "all")
    error("mechanics:plotting:InvalidPopulationInterpolation", ...
        "Population interpolation produced nonfinite values in the common domain.");
end
populationMedian = median(interpolatedStress, 2);
end

function output = localParameterText(parameterNames, parameters, ...
        derivedNames, derivedValues, stressUnit)
lines = "Selected parameters:";
for index = 1:numel(parameterNames)
    lines(end+1, 1) = localQuantityLine( ...
        parameterNames(index), parameters(index), stressUnit); %#ok<AGROW>
end
if ~isempty(derivedNames)
    lines(end+1, 1) = "Derived quantities:"; %#ok<AGROW>
    for index = 1:numel(derivedNames)
        lines(end+1, 1) = localQuantityLine( ...
            derivedNames(index), derivedValues(index), stressUnit); %#ok<AGROW>
    end
end
output = join(lines, newline);
end

function line = localQuantityLine(name, value, unit)
displayName = localDisplayQuantityName(name);
line = displayName + " = " + compose("%.6g", value);
if strlength(string(unit)) > 0
    line = line + " " + string(unit);
end
end

function displayName = localDisplayQuantityName(name)
normalizedName = lower(strtrim(string(name)));
switch normalizedName
    case "mu"
        displayName = "\mu";
    case "mu0"
        displayName = "\mu_0";
    otherwise
        displayName = string(name);
end
end

function alignment = localVerticalAlignment(modeName)
if modeName == "compression"
    alignment = "top";
else
    alignment = "bottom";
end
end

function localValidateModeContexts(specimens, modeName)
contexts = {specimens.Context};
reference = contexts{1};
for index = 2:numel(contexts)
    current = contexts{index};
    if current.deformationMeasure ~= reference.deformationMeasure || ...
            current.stressMeasure ~= reference.stressMeasure
        error("mechanics:plotting:InconsistentJointModeContext", ...
            "Mode %s contains incompatible constitutive contexts.", modeName);
    end
end
end
