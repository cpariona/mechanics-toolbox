%RUN_SYNTHETIC_TENSION_ANALYSIS Demonstrate the Phase 1 public API.
config = mechanics.config.tensionConfig();
config.preprocessing.smoothing.enabled = false;
rawCurve.displacement = linspace(0, 10, 201)';
rawCurve.force = 2.5 .* rawCurve.displacement;
rawCurve.units.force = "N";
rawCurve.units.displacement = "mm";
specimen.geometry.initialLength = 25;
specimen.geometry.initialArea = 10;
curve = mechanics.preprocessing.prepareCurve(rawCurve, config.preprocessing);
curve = mechanics.analysis.computeUniaxialMeasures(curve, specimen.geometry, config.mechanics);
modulusResult = mechanics.analysis.computeTangentModulus(curve, config.analysis);
fprintf('Median tangent modulus: %.6g %s\n', modulusResult.medianModulus, curve.units.stress);
mechanics.plotting.plotStressStrain(curve, Title="Synthetic tension example");
