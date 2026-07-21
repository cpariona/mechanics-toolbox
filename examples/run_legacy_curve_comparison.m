%RUN_LEGACY_CURVE_COMPARISON Compare new and legacy processed curves.
startup;

% Replace these structures with curves produced by each pipeline.
legacyCurve.strain = linspace(0, 1, 101)';
legacyCurve.stress = legacyCurve.strain.^2;

newCurve.strain = legacyCurve.strain;
newCurve.stress = legacyCurve.stress;

comparison = mechanics.validation.compareCurves( ...
    legacyCurve, newCurve, 1e-6);

disp(comparison);

figure("Color", "w");
plot(comparison.commonStrain, comparison.referenceStress, ...
    "LineWidth", 1.5);
hold on;
plot(comparison.commonStrain, comparison.candidateStress, "--", ...
    "LineWidth", 1.5);
xlabel("Strain");
ylabel("Stress");
legend("Legacy", "New", "Location", "best");
grid on;
box on;
