function tests = test_constitutive_fitting
tests = functiontests(localfunctions);
end
function setupOnce(~)
startup;
end
function testNeoHookeanParameterRecovery(testCase)
strain = linspace(0,0.8,101)'; context.inputMeasure="engineering-strain"; context.outputStressMeasure="nominal"; trueMu=0.125;
stress=mechanics.models.evaluateModel("neo-hookean",strain,trueMu,context); config=mechanics.config.fittingConfig(); config.initialGuess=0.4; config.numberOfStarts=4;
result=mechanics.fitting.fitModel("neo-hookean",strain,stress,context,config); verifyEqual(testCase,result.parameters,trueMu,'RelTol',1e-5); verifyLessThan(testCase,result.metrics.rmse,1e-8);
end
function testMooneyRivlinRecoveryWithNoise(testCase)
rng(12); strain=linspace(0,1,151)'; context.inputMeasure="engineering-strain"; context.outputStressMeasure="nominal"; trueParameters=[0.08,0.025];
cleanStress=mechanics.models.evaluateModel("mooney-rivlin",strain,trueParameters,context); config=mechanics.config.fittingConfig(); config.initialGuess=[0.04,0.04]; config.numberOfStarts=10;
result=mechanics.fitting.fitModel("mooney-rivlin",strain,cleanStress+2e-4*randn(size(cleanStress)),context,config); verifyEqual(testCase,result.parameters,trueParameters,'AbsTol',0.005); verifyGreaterThan(testCase,result.metrics.rSquared,0.999);
end
function testBoundsAreRespected(testCase)
strain=linspace(0,0.5,41)'; context.inputMeasure="engineering-strain"; stress=mechanics.models.evaluateModel("neo-hookean",strain,2,context); config=mechanics.config.fittingConfig(); config.initialGuess=0.2; config.lowerBounds=0.1; config.upperBounds=0.5; config.numberOfStarts=3;
result=mechanics.fitting.fitModel("neo-hookean",strain,stress,context,config); verifyGreaterThanOrEqual(testCase,result.parameters,0.1); verifyLessThanOrEqual(testCase,result.parameters,0.5); verifyEqual(testCase,result.parameters,0.5,'AbsTol',1e-6);
end
function testNonfiniteObservationsAreRemoved(testCase)
strain=[0;0.1;NaN;0.3;0.4;0.5]; stress=mechanics.models.evaluateModel("neo-hookean",[0;0.1;0.2;0.3;0.4;0.5],1,struct()); stress(4)=Inf; config=mechanics.config.fittingConfig(); config.numberOfStarts=2;
result=mechanics.fitting.fitModel("neo-hookean",strain,stress,struct(),config); verifyEqual(testCase,numel(result.measuredStress),4);
end
function testMetricCalculation(testCase)
metrics=mechanics.fitting.computeFitMetrics([1;2;3],[1;2;3],1); verifyEqual(testCase,metrics.rmse,0); verifyEqual(testCase,metrics.rSquared,1);
end
function testMultipleModelComparison(testCase)
strain=linspace(0,0.8,81)'; context.inputMeasure="engineering-strain"; stress=mechanics.models.evaluateModel("neo-hookean",strain,0.2,context); config=mechanics.config.fittingConfig(); config.numberOfStarts=3;
comparison=mechanics.fitting.fitMultipleModels(["neo-hookean","mooney-rivlin"],strain,stress,context,config); verifyEqual(testCase,height(comparison.summary),2); verifyTrue(testCase,any(comparison.summary.Model=="neo-hookean"));
end
function testMismatchedInputRejected(testCase)
verifyError(testCase,@() mechanics.fitting.fitModel("neo-hookean",[0;0.1],[0],struct(),mechanics.config.fittingConfig()),"mechanics:fitting:SizeMismatch");
end
