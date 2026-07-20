function figureHandle = plotStressStrain(curve, options)
%PLOTSTRESSSTRAIN Plot an already processed stress-strain curve.
arguments
    curve (1,1) struct
    options.Title string = "Stress-strain curve"
    options.DisplayName string = "Experimental"
end
figureHandle = figure("Color", "w");
plot(curve.strain, curve.stress, "LineWidth", 1.5, "DisplayName", options.DisplayName);
grid on
xlabel(sprintf("Strain [%s]", curve.units.strain));
ylabel(sprintf("Stress [%s]", curve.units.stress));
title(options.Title);
legend("Location", "best");
end
