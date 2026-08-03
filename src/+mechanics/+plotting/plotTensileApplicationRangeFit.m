function figureHandle = plotTensileApplicationRangeFit(result)
%PLOTTENSILEAPPLICATIONRANGEFIT Plot tensile fits and residuals by specimen.
arguments
    result (1,1) struct
end
localValidateResult(result);
specimens = result.selectedFit.specimens(:);
context = specimens(1).Context;
strainUnit = string(specimens(1).StrainUnit);
stressUnit = string(specimens(1).StressUnit);
localValidateMetadata(specimens);
figureHandle = figure("Color", "w");
layout = tiledlayout(figureHandle, 2, 1, "TileSpacing", "compact", "Padding", "compact");
colors = lines(numel(specimens));
fitAxes = nexttile(layout, 1);
hold(fitAxes, "on")
for index = 1:numel(specimens)
    specimen = specimens(index);
    plot(fitAxes, specimen.Deformation, specimen.MeasuredStress, "-", "Color", colors(index,:), "LineWidth", 0.9, "DisplayName", specimen.SourceSpecimenId + " measured");
    plot(fitAxes, specimen.Deformation, specimen.PredictedStress, "--", "Color", colors(index,:), "LineWidth", 1.5, "DisplayName", specimen.SourceSpecimenId + " predicted");
end
ylabel(fitAxes, mechanics.plotting.mechanicalAxisLabel("stress", context.stressMeasure, stressUnit));
title(fitAxes, "Tensile application-range fit (" + string(result.selectedModelName) + ")");
legend(fitAxes, "Location", "northwest", "Interpreter", "none");
grid(fitAxes, "on"); box(fitAxes, "on"); hold(fitAxes, "off")
residualAxes = nexttile(layout, 2);
hold(residualAxes, "on")
yline(residualAxes, 0, "k:", "HandleVisibility", "off");
for index = 1:numel(specimens)
    specimen = specimens(index);
    plot(residualAxes, specimen.Deformation, specimen.Residuals, "-", "Color", colors(index,:), "LineWidth", 1.0, "DisplayName", specimen.SourceSpecimenId);
end
xlabel(residualAxes, mechanics.plotting.mechanicalAxisLabel("deformation", context.deformationMeasure, strainUnit));
ylabel(residualAxes, mechanics.plotting.mechanicalAxisLabel("residual", context.stressMeasure, stressUnit));
title(residualAxes, "Residual = measured - predicted");
legend(residualAxes, "Location", "best", "Interpreter", "none");
grid(residualAxes, "on"); box(residualAxes, "on"); hold(residualAxes, "off")
end

function localValidateResult(result)
required = ["selectedModelName", "selectedFit"];
if ~all(isfield(result, required)) || ~isfield(result.selectedFit, "specimens") || isempty(result.selectedFit.specimens)
    error("mechanics:plotting:InvalidTensileApplicationRangeResult", "Provide a completed tensile application-range result.");
end
requiredSpecimen = ["SourceSpecimenId", "Deformation", "MeasuredStress", "PredictedStress", "Residuals", "Context", "StrainUnit", "StressUnit"];
if ~all(isfield(result.selectedFit.specimens, requiredSpecimen))
    error("mechanics:plotting:IncompleteTensileApplicationRangeFit", "Selected tensile specimens are missing plotting fields.");
end
end

function localValidateMetadata(specimens)
reference = specimens(1);
for index = 2:numel(specimens)
    current = specimens(index);
    if current.StrainUnit ~= reference.StrainUnit || current.StressUnit ~= reference.StressUnit || current.Context.deformationMeasure ~= reference.Context.deformationMeasure || current.Context.stressMeasure ~= reference.Context.stressMeasure
        error("mechanics:plotting:InconsistentTensileApplicationRangeMetadata", "Tensile fit specimens must share units and constitutive measures.");
    end
end
end
