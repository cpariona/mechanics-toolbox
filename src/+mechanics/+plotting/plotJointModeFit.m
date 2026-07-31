function figureHandle = plotJointModeFit(result, modeName)
%PLOTJOINTMODEFIT Plot measured specimens and one selected joint-model curve.
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
maximumDisplayedPoints = 160;
for index = 1:numel(modeSpecimens)
    specimen = modeSpecimens(index);
    displayIndices = localDisplayIndices( ...
        specimen.ObservationCount, maximumDisplayedPoints);
    plot(axesHandle, specimen.Deformation(displayIndices), ...
        specimen.MeasuredStress(displayIndices), ".", ...
        "LineStyle", "none", ...
        "MarkerSize", 6, ...
        "Color", colors(index, :), ...
        "DisplayName", specimen.OriginalSpecimenId + " measured");
end

minimumDeformation = min(arrayfun(@(item) min(item.Deformation), modeSpecimens));
maximumDeformation = max(arrayfun(@(item) max(item.Deformation), modeSpecimens));
referenceDeformation = linspace(minimumDeformation, maximumDeformation, 600)';
referenceStress = mechanics.models.evaluateModel( ...
    string(result.selectedModelName), referenceDeformation, parameters, ...
    modeSpecimens(1).Context);
plot(axesHandle, referenceDeformation, referenceStress, "k--", ...
    "LineWidth", 1.8, ...
    "DisplayName", "Joint selected fit (" + ...
    string(result.selectedModelName) + ")");

xlabel(axesHandle, "Deformation")
ylabel(axesHandle, "Stress")
title(axesHandle, "Joint material characterization: " + modeName + ...
    " (" + string(result.selectedModelName) + ")")
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
    localParameterText(parameterNames, parameters, modeSpecimens(1).StressUnit), ...
    "Units", "normalized", ...
    "HorizontalAlignment", horizontalAlignment, ...
    "VerticalAlignment", localVerticalAlignment(modeName), ...
    "Interpreter", "none", ...
    "BackgroundColor", "w", ...
    "EdgeColor", [0.4, 0.4, 0.4], ...
    "Margin", 5, ...
    "FontSize", 9);
grid(axesHandle, "on")
box(axesHandle, "on")
hold(axesHandle, "off")
end

function indices = localDisplayIndices(observationCount, maximumDisplayedPoints)
if observationCount <= maximumDisplayedPoints
    indices = (1:observationCount)';
else
    indices = unique(round(linspace(1, observationCount, ...
        maximumDisplayedPoints)))';
end
end

function output = localParameterText(parameterNames, parameters, stressUnit)
lines = "Selected parameters:";
for index = 1:numel(parameterNames)
    line = parameterNames(index) + " = " + compose("%.6g", parameters(index));
    if strlength(string(stressUnit)) > 0
        line = line + " " + string(stressUnit);
    end
    lines(end+1, 1) = line; %#ok<AGROW>
end
output = join(lines, newline);
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
