function figureHandle = plotStressStrain(curve, options)
%PLOTSTRESSSTRAIN Plot an already processed stress-strain curve.
arguments
    curve (1,1) struct
    options.Title string = "Stress-strain curve"
    options.DisplayName string = "Experimental"
end
strainUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "deformation", string(curve.units.strain));
stressUnit = mechanics.plotting.mechanicalDisplayUnit( ...
    "stress", string(curve.units.stress));

figureHandle = figure("Color", "w");
plot(curve.strain, curve.stress, "LineWidth", 1.5, ...
    "DisplayName", options.DisplayName);
grid on
xlabel(mechanics.plotting.formatUnitLabel("Strain", strainUnit));
ylabel(mechanics.plotting.formatUnitLabel("Stress", stressUnit));
title(options.Title);
legend("Location", "best");
end
