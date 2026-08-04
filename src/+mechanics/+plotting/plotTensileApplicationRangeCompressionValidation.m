function figureHandle = plotTensileApplicationRangeCompressionValidation(result)
%PLOTTENSILEAPPLICATIONRANGECOMPRESSIONVALIDATION Plot fixed-parameter validation.
arguments
    result (1,1) struct
end
if ~isfield(result, "hasCompressionValidation") || ...
        ~result.hasCompressionValidation || ...
        ~isfield(result, "compressionValidation") || ...
        ~isfield(result.compressionValidation, "specimens") || ...
        isempty(result.compressionValidation.specimens)
    error("mechanics:plotting:MissingCompressionValidation", ...
        "Provide a result containing compression validation.");
end
specimens = result.compressionValidation.specimens(:);
required = ["SpecimenId", "Deformation", "MeasuredStress", ...
    "Context", "StrainUnit", "StressUnit"];
if ~all(isfield(specimens, required))
    error("mechanics:plotting:IncompleteCompressionValidation", ...
        "Compression validation specimens are missing plotting fields.");
end
localValidateMetadata(specimens);
context = specimens(1).Context;
strainUnit = string(specimens(1).StrainUnit);
stressUnit = string(specimens(1).StressUnit);

minimumDeformation = min(arrayfun(@(item) min(item.Deformation), specimens));
maximumDeformation = max(arrayfun(@(item) max(item.Deformation), specimens));
referenceDeformation = linspace(minimumDeformation, maximumDeformation, 600)';
referencePrediction = mechanics.models.evaluateModel( ...
    string(result.selectedModelName), referenceDeformation, ...
    result.selectedFit.parameters, context);

colors = lines(numel(specimens));
figureHandle = figure("Color", "w");
layout = tiledlayout(figureHandle, 2, 1, ...
    "TileSpacing", "loose", "Padding", "compact");
fitAxes = nexttile(layout, 1);
hold(fitAxes, "on")
for index = 1:numel(specimens)
    specimen = specimens(index);
    plot(fitAxes, specimen.Deformation, specimen.MeasuredStress, "-", ...
        "Color", colors(index,:), "LineWidth", 0.9, ...
        "DisplayName", specimen.SpecimenId + " measured");
end
plot(fitAxes, referenceDeformation, referencePrediction, "k--", ...
    "LineWidth", 1.8, ...
    "DisplayName", "Shared tensile-calibrated prediction");
ylabel(fitAxes, mechanics.plotting.mechanicalAxisLabel( ...
    "stress", context.stressMeasure, stressUnit));
title(fitAxes, ...
    "Compression validation with fixed tensile parameters (no refit)");
legend(fitAxes, "Location", "southeast", "Interpreter", "none");
grid(fitAxes, "on"); box(fitAxes, "on"); hold(fitAxes, "off")

residualAxes = nexttile(layout, 2);
hold(residualAxes, "on")
yline(residualAxes, 0, "k:", "HandleVisibility", "off");
for index = 1:numel(specimens)
    specimen = specimens(index);
    prediction = mechanics.models.evaluateModel( ...
        string(result.selectedModelName), specimen.Deformation, ...
        result.selectedFit.parameters, specimen.Context);
    magnitudeResidual = abs(specimen.MeasuredStress) - abs(prediction);
    plot(residualAxes, specimen.Deformation, magnitudeResidual, "-", ...
        "Color", colors(index,:), "LineWidth", 1.0, ...
        "DisplayName", specimen.SpecimenId);
end
xlabel(residualAxes, mechanics.plotting.mechanicalAxisLabel( ...
    "deformation", context.deformationMeasure, strainUnit));
ylabel(residualAxes, mechanics.plotting.mechanicalAxisLabel( ...
    "compression-magnitude-residual", context.stressMeasure, stressUnit));
title(residualAxes, ...
    "Magnitude residual = |measured| - |shared prediction|");
legend(residualAxes, "Location", "best", "Interpreter", "none");
grid(residualAxes, "on"); box(residualAxes, "on"); hold(residualAxes, "off")
end

function localValidateMetadata(specimens)
reference = specimens(1);
for index = 2:numel(specimens)
    current = specimens(index);
    if current.StrainUnit ~= reference.StrainUnit || ...
            current.StressUnit ~= reference.StressUnit || ...
            current.Context.deformationMeasure ~= reference.Context.deformationMeasure || ...
            current.Context.stressMeasure ~= reference.Context.stressMeasure
        error("mechanics:plotting:InconsistentCompressionValidationMetadata", ...
            "Compression validation specimens must share units and measures.");
    end
end
end
