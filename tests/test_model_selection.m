function tests = test_model_selection
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testStableNeoHookeanSelection(testCase)
strain = linspace(0, 0.8, 121)';
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
stress = mechanics.models.evaluateModel("neo-hookean", strain, 0.15, context);

fitConfig = mechanics.config.fittingConfig();
fitConfig.numberOfStarts = 4;

selectionConfig = mechanics.config.modelSelectionConfig();
selectionConfig.windowFractions = [0.5, 0.75, 1.0];

study = mechanics.fitting.fitAcrossWindows( ...
    ["neo-hookean", "mooney-rivlin"], ...
    strain, stress, context, fitConfig, selectionConfig);

verifyTrue(testCase, study.selection.hasEligibleModel);
verifyEqual(testCase, study.selection.bestModel, "neo-hookean");
verifyTrue(testCase, isfinite( ...
    study.summary.MaximumSharedDomainNormalizedRMSE(1)));
end

function testParameterCVDoesNotControlEligibility(testCase)
summary = table( ...
    ["neo-hookean"; "yeoh"], ...
    [true; true], ...
    [0.1; 0.01], ...
    [10; 1], ...
    [11; 2], ...
    [0.05; 0.90], ...
    [0.2; 0.005], ...
    [1; 3], ...
    'VariableNames', {'Model','Eligible','FullWindowRMSE', ...
    'FullWindowAIC','FullWindowBIC','MaximumRelativeParameterCV', ...
    'MaximumSharedDomainNormalizedRMSE','FullWindowParameterCount'});

selection = mechanics.fitting.selectBestModel( ...
    summary, mechanics.config.modelSelectionConfig());

verifyEqual(testCase, selection.bestModel, "yeoh");
end

function testWindowRecordsAreCreated(testCase)
strain = linspace(0, 0.6, 101)';
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
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

function testCompressionWindowsGrowFromZero(testCase)
strain = linspace(0, -0.4, 101)';
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
stress = mechanics.models.evaluateModel("neo-hookean", strain, 0.2, context);
selectionConfig = mechanics.config.modelSelectionConfig();
selectionConfig.windowFractions = [0.5, 0.75, 1.0];
selectionConfig.minimumObservations = 10;

study = mechanics.fitting.fitAcrossWindows( ...
    "neo-hookean", strain, stress, context, ...
    mechanics.config.fittingConfig(), selectionConfig);
maximumDeformation = [study.records.maximumDeformation];

verifyEqual(testCase, maximumDeformation, [-0.2, -0.3, -0.4], ...
    "AbsTol", 1e-12);
verifyEqual(testCase, study.referenceDeformation, 0, "AbsTol", 1e-12);
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
    'FullWindowAIC','FullWindowBIC', ...
    'MaximumSharedDomainNormalizedRMSE'});
config = mechanics.config.modelSelectionConfig();
config.rankingMetric = "unknown";

verifyError(testCase, @() mechanics.fitting.selectBestModel(summary, config), ...
    "mechanics:fitting:UnknownRankingMetric");
end

function testNoEligibleModelIsReported(testCase)
summary = table("neo-hookean", false, 1, 2, 3, 0.1, ...
    'VariableNames', {'Model','Eligible','FullWindowRMSE', ...
    'FullWindowAIC','FullWindowBIC', ...
    'MaximumSharedDomainNormalizedRMSE'});
selection = mechanics.fitting.selectBestModel( ...
    summary, mechanics.config.modelSelectionConfig());

verifyFalse(testCase, selection.hasEligibleModel);
verifyEqual(testCase, selection.bestModel, "");
end
