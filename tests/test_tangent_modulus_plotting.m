function tests = test_tangent_modulus_plotting
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testAutomaticPlotStartPreservesComputedModulus(testCase)
curve.strain = linspace(0, 1, 101)';
curve.stress = curve.strain .^ 2;
config = mechanics.config.tensionConfig().analysis;
config.summaryStrainRange = [0.2, 0.8];
config.modulusPlotStartStrain = NaN;
config.modulusPlotAutomaticStartFraction = 0.10;

result = mechanics.analysis.computeTangentModulus(curve, config);

verifyEqual(testCase, result.modulusPlotStartStrain, 0.10, ...
    "AbsTol", 1e-12);
verifyTrue(testCase, all(isnan( ...
    result.tangentModulusForPlot(result.strain < 0.10))));
verifyTrue(testCase, all(isfinite(result.tangentModulus)));
verifyTrue(testCase, any(isfinite( ...
    result.tangentModulusForPlot(result.strain >= 0.10))));
end

function testManualPlotStartUsesConfiguredStrain(testCase)
curve.strain = linspace(0, 1, 101)';
curve.stress = 3 .* curve.strain;
config = mechanics.config.tensionConfig().analysis;
config.summaryStrainRange = [0.2, 0.8];
config.modulusPlotStartStrain = 0.25;

result = mechanics.analysis.computeTangentModulus(curve, config);

verifyEqual(testCase, result.modulusPlotStartStrain, 0.25);
verifyTrue(testCase, all(isnan( ...
    result.tangentModulusForPlot(result.strain < 0.25))));
verifyTrue(testCase, all(isfinite( ...
    result.tangentModulusForPlot(result.strain >= 0.25))));
end

function testInvalidAutomaticFractionRejected(testCase)
curve.strain = linspace(0, 1, 21)';
curve.stress = curve.strain;
config = mechanics.config.tensionConfig().analysis;
config.summaryStrainRange = [0.2, 0.8];
config.modulusPlotStartStrain = NaN;
config.modulusPlotAutomaticStartFraction = 1;

verifyError(testCase, ...
    @() mechanics.analysis.computeTangentModulus(curve, config), ...
    "mechanics:analysis:InvalidModulusPlotStartFraction");
end

function testProportionalSummaryRangeResolvesAgainstRetainedStrain(testCase)
curve.strain = linspace(-0.36, 0, 37)';
curve.stress = 2 .* curve.strain;
config = mechanics.config.compressionConfig().analysis;
config.summaryStrainRangeMode = "proportional";
config.summaryStrainRange = [0.25, 0.75];

result = mechanics.analysis.computeTangentModulus(curve, config);

verifyEqual(testCase, result.summaryStrainRange, [-0.27, -0.09], ...
    "AbsTol", 1e-12);
verifyEqual(testCase, result.summaryStrainRangeMode, "proportional");
verifyEqual(testCase, result.configuredSummaryStrainRange, [0.25, 0.75]);
verifyEqual(testCase, result.medianModulus, 2, "AbsTol", 1e-10);
end
