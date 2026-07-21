function tests = test_phase4_model_selection
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testStableNeoHookeanSelection(testCase)
strain = linspace(0, 0.8, 121)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
stress = mechanics.models.evaluateModel("neo-hookean", strain, 0.15, context);

fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 4;

selectionConfig = mechanics.config.modelSelectionConfig();
selectionConfig.windowFractions = [0.5, 0.75, 1.0];
selectionConfig.maximumRelativeParameterCV = 0.05;

study = mechanics.fitting.fitAcrossWindows( ...
    ["neo-hookean", "mooney-rivlin"], ...
    strain, stress, context, fitConfig, selectionConfig);

verifyTrue(testCase, study.selection.hasEligibleModel);
verifyEqual(testCase, study.selection.bestModel, "neo-hookean");
end

function testWindowRecordsAreCreated(testCase)
strain = linspace(0, 0.6, 101)';
context.inputMeasure = "engineering-strain";
context.outputStressMeasure = "nominal";
stress = mechanics.models.evaluateModel("neo-hookean", strain, 0.2, context);

selectionConfig = mechanics.config.modelSelectionConfig();
selectionConfig.windowFractions = [0.4, 0.7, 1.0];
selectionConfig.minimumObservations = 10;

study = mechanics.fitting.fitAcrossWindows( ...
    "neo-hookean", strain, stress, context, ...
    mechanics.config.fittingConfig(), selectionConfig);

verifyEqual(testCase, numel(study.records), 3);
verifyEqual(testCase, study.summary.WindowCount, 3);
verifyEqual(testCase, study.summary.SuccessfulWindowCount, 3);
end

function testMismatchedInputRejected(testCase)
verifyError(testCase, @() mechanics.fitting.fitAcrossWindows( ...
    "neo-hookean", [0; 0.1], 0, struct(), ...
    mechanics.config.fittingConfig(), ...
    mechanics.config.modelSelectionConfig()), ...
    "mechanics:fitting:SizeMismatch");
end

function testInvalidFractionsRejected(testCase)
strain = linspace(0, 0.5, 50)';
stress = strain;
config = mechanics.config.modelSelectionConfig();
config.windowFractions = [0.5, 1.2];

verifyError(testCase, @() mechanics.fitting.fitAcrossWindows( ...
    "neo-hookean", strain, stress, struct(), ...
    mechanics.config.fittingConfig(), config), ...
    "mechanics:fitting:InvalidWindowFractions");
end

function testUnknownRankingMetricRejected(testCase)
summary = table("neo-hookean", true, 1, 2, 3, 0.1, ...
    'VariableNames', {'Model','Eligible','FullWindowRMSE', ...
    'FullWindowAIC','FullWindowBIC','MaximumRelativeParameterCV'});
config = mechanics.config.modelSelectionConfig();
config.rankingMetric = "unknown";

verifyError(testCase, @() mechanics.fitting.selectBestModel(summary, config), ...
    "mechanics:fitting:UnknownRankingMetric");
end

function testNoEligibleModelIsReported(testCase)
summary = table("neo-hookean", false, 1, 2, 3, 0.9, ...
    'VariableNames', {'Model','Eligible','FullWindowRMSE', ...
    'FullWindowAIC','FullWindowBIC','MaximumRelativeParameterCV'});
selection = mechanics.fitting.selectBestModel( ...
    summary, mechanics.config.modelSelectionConfig());

verifyFalse(testCase, selection.hasEligibleModel);
verifyEqual(testCase, selection.bestModel, "");
end
