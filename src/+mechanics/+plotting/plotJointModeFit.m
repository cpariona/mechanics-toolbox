function figureHandle = plotJointModeFit(result, modeName)
%PLOTJOINTMODEFIT Plot measured and selected joint-model curves for one mode.
arguments
    result (1,1) struct
    modeName (1,1) string
end

required = ["selectedModelName","selectedFit"];
if ~all(isfield(result, required)) || ~isfield(result.selectedFit, "specimens")
    error("mechanics:plotting:InvalidJointCharacterizationResult", ...
        "Provide a completed joint material-characterization result.");
end

modeName = lower(strtrim(modeName));
specimens = result.selectedFit.specimens;
mask = string({specimens.Mode})' == modeName;
if ~any(mask)
    error("mechanics:plotting:UnknownJointMode", ...
        "No selected-fit specimens exist for mode %s.", modeName);
end

figureHandle = figure("Color", "w");
hold on
indices = find(mask);
for index = 1:numel(indices)
    specimen = specimens(indices(index));
    measuredLabel = specimen.OriginalSpecimenId + " measured";
    predictedLabel = specimen.OriginalSpecimenId + " selected fit";
    plot(specimen.Deformation, specimen.MeasuredStress, ".", ...
        "DisplayName", measuredLabel);
    plot(specimen.Deformation, specimen.PredictedStress, "-", ...
        "LineWidth", 1.4, "DisplayName", predictedLabel);
end
xlabel("Deformation")
ylabel("Stress")
title("Joint material characterization: " + modeName + ...
    " (" + string(result.selectedModelName) + ")")
legend("Location", "best", "Interpreter", "none")
grid on
box on
end
