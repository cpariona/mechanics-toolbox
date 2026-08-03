function figureHandle = plotTensileApplicationRangeCompressionValidation(result)
%PLOTTENSILEAPPLICATIONRANGECOMPRESSIONVALIDATION Plot fixed-parameter validation.
arguments
    result (1,1) struct
end
if ~isfield(result, "hasCompressionValidation") || ~result.hasCompressionValidation || ~isfield(result, "compressionValidation") || ~isfield(result.compressionValidation, "specimens") || isempty(result.compressionValidation.specimens)
    error("mechanics:plotting:MissingCompressionValidation", "Provide a result containing compression validation.");
end
specimens = result.compressionValidation.specimens(:);
required = ["SpecimenId", "Deformation", "MeasuredStress", "PredictedStress", "Residuals", "Context", "StrainUnit", "StressUnit"];
if ~all(isfield(specimens, required))
    error("mechanics:plotting:IncompleteCompressionValidation", "Compression validation specimens are missing plotting fields.");
end
localValidateMetadata(specimens);
context = specimens(1).Context;
strainUnit = string(specimens(1).StrainUnit);
stressUnit = string(specimens(1).StressUnit);
colors = lines(numel(specimens));
figureHandle = figure("Color", "w");
layout = tiledlayout(figureHandle, 2, 1, "TileSpacing", "compact", "Padding", "compact");
fitAxes = nexttile(layout, 1);
hold(fitAxes, "on")
for index = 1:numel(specimens)
    specimen = specimens(index);
    plot(fitAxes, specimen.Deformation, specimen.MeasuredStress, "-", "Color", colors(index,:), "LineWidth", 0.9, "DisplayName", specimen.SpecimenId + " measured");
    plot(fitAxes, specimen.Deformation, specimen.PredictedStress, "--", "Color", colors(index,:), "LineWidth", 1.5, "DisplayName", specimen.SpecimenId + " predicted");
end
ylabel(fitAxes, mechanics.plotting.mechanicalAxisLabel("stress", context.stressMeasure, stressUnit));
title(fitAxes, "Compression validation with fixed tensile parameters (no refit)");
legend(fitAxes, "Location", "southeast", "Interpreter", "none");
grid(fitAxes, "on"); box(fitAxes, "on"); hold(fitAxes, "off")
residualAxes = nexttile(layout, 2);
hold(residualAxes, "on")
yline(residualAxes, 0, "k:", "HandleVisibility", "off");
for index = 1:numel(specimens)
    specimen = specimens(index);
    plot(residualAxes, specimen.Deformation, specimen.Residuals, "-", "Color", colors(index,:), "LineWidth", 1.0, "DisplayName", specimen.SpecimenId);
end
xlabel(residualAxes, mechanics.plotting.mechanicalAxisLabel("deformation", context.deformationMeasure, strainUnit));
ylabel(residualAxes, mechanics.plotting.mechanicalAxisLabel("residual", context.stressMeasure, stressUnit));
title(residualAxes, "Residual = measured - predicted");
legend(residualAxes, "Location", "best", "Interpreter", "none");
grid(residualAxes, "on"); box(residualAxes, "on"); hold(residualAxes, "off")
end

function localValidateMetadata(specimens)
reference = specimens(1);
for index = 2:numel(specimens)
    current = specimens(index);
    if current.StrainUnit ~= reference.StrainUnit || current.StressUnit ~= reference.StressUnit || current.Context.deformationMeasure ~= reference.Context.deformationMeasure || current.Context.stressMeasure ~= reference.Context.stressMeasure
        error("mechanics:plotting:InconsistentCompressionValidationMetadata", "Compression validation specimens must share units and measures.");
    end
end
end
