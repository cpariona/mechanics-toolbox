function tests = test_tensile_application_range_selection
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testBestObjectiveIsSelectedWhenNotPracticallyEquivalent(testCase)
config = localConfig();
candidates = [ ...
    localCandidate("neo-hookean", 0.020, true, 0.4); ...
    localCandidate("mooney-rivlin", 0.010, true, [0.1, 0.1]); ...
    localCandidate("yeoh-third-order", 0.005, true, [0.1, 0.01, 0.001])];
result = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);
verifyEqual(testCase, result.selectedModelName, "yeoh-third-order");
verifyEqual(testCase, result.referenceProperties.names, "mu0");
verifyEqual(testCase, result.referenceProperties.values, 0.2, ...
    "AbsTol", 1e-12);
end

function testSimplerModelWinsInsidePracticalTolerance(testCase)
config = localConfig();
config.selection.practicalObjectiveTolerance = 0.05;
candidates = [ ...
    localCandidate("neo-hookean", 0.0104, true, 0.42); ...
    localCandidate("mooney-rivlin", 0.0101, true, [0.1, 0.1]); ...
    localCandidate("yeoh-third-order", 0.0100, true, [0.1, 0.01, 0.001])];
result = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);
verifyEqual(testCase, result.selectedModelName, "neo-hookean");
verifyTrue(testCase, all(result.candidateSummary.PracticallyEquivalent));
verifyEqual(testCase, result.referenceProperties.values, 0.42, ...
    "AbsTol", 1e-12);
end

function testSecondOrderYeohIsTreatedAsTwoParameterModel(testCase)
config = localConfig();
config.selection.practicalObjectiveTolerance = 0.05;
config.selection.tieBreakOrder = ["yeoh-second-order"; "yeoh-third-order"];
candidates = [ ...
    localCandidate("yeoh-second-order", 0.0102, true, [0.15, 0.02]); ...
    localCandidate("yeoh-third-order", 0.0100, true, [0.15, 0.02, 0.001])];
result = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);

verifyEqual(testCase, result.candidateSummary.ParameterCount, [2; 3]);
verifyTrue(testCase, all(result.candidateSummary.PracticallyEquivalent));
verifyEqual(testCase, result.selectedModelName, "yeoh-second-order");
verifyEqual(testCase, result.referenceProperties.names, "mu0");
verifyEqual(testCase, result.referenceProperties.values, 0.3, ...
    "AbsTol", 1e-12);
end

function testRegistryAliasesCannotCreateDuplicateCandidates(testCase)
config = localConfig();
candidates = [ ...
    localCandidate("neo-hookean", 0.0102, true, 0.3); ...
    localCandidate("neohookean", 0.0100, true, 0.4)];
verifyError(testCase, @() mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config), ...
    "mechanics:workflow:DuplicateTensileApplicationRangeCandidates");
end

function testTieBreakOrderMustContainEveryCandidate(testCase)
config = localConfig();
config.selection.tieBreakOrder = ["neo-hookean"; "mooney-rivlin"];
candidates = [ ...
    localCandidate("neo-hookean", 0.01, true, 0.4); ...
    localCandidate("yeoh-third-order", 0.01, true, [0.1, 0.01, 0.001])];
verifyError(testCase, @() mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config), ...
    "mechanics:workflow:InvalidTensileApplicationRangeTieBreakOrder");
end

function testFailedAndNonconvergedCandidatesAreIneligible(testCase)
config = localConfig();
candidates = [ ...
    localFailedCandidate("neo-hookean"); ...
    localCandidate("mooney-rivlin", 0.005, false, [0.1, 0.1]); ...
    localCandidate("yeoh-third-order", 0.010, true, [0.1, 0.01, 0.001])];
result = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);
verifyEqual(testCase, result.selectedModelName, "yeoh-third-order");
verifyEqual(testCase, result.candidateSummary.Eligible, ...
    [false; false; true]);
end

function testConvergenceRequirementCanBeDisabled(testCase)
config = localConfig();
config.selection.requireConvergence = false;
candidates = [ ...
    localCandidate("neo-hookean", 0.01, false, 0.4); ...
    localCandidate("mooney-rivlin", 0.02, true, [0.1, 0.1])];
result = mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config);
verifyEqual(testCase, result.selectedModelName, "neo-hookean");
end

function testNoEligibleCandidateIsRejected(testCase)
config = localConfig();
candidates = [ ...
    localFailedCandidate("neo-hookean"); ...
    localCandidate("mooney-rivlin", Inf, true, [0.1, 0.1])];
verifyError(testCase, @() mechanics.workflow.selectTensileApplicationRangeModel( ...
    candidates, config), ...
    "mechanics:workflow:NoEligibleTensileApplicationRangeModel");
end

function testAllRegisteredModelsExposeMu0(testCase)
models = ["neo-hookean"; "mooney-rivlin"; ...
    "yeoh-second-order"; "yeoh-third-order"];
parameters = {0.4, [0.1, 0.2], [0.15, 0.01], [0.15, 0.01, 0.001]};
expected = [0.4; 0.6; 0.3; 0.3];
for index = 1:numel(models)
    model = mechanics.models.modelRegistry(models(index));
    verifyEqual(testCase, model.derivedQuantityNames, "mu0");
    actual = model.evaluateDerivedQuantities(parameters{index});
    verifyEqual(testCase, actual, expected(index), "AbsTol", 1e-12);
end
end

function config = localConfig()
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.selection.practicalObjectiveTolerance = 0.02;
end

function candidate = localCandidate(modelName, objective, converged, parameters)
candidate.modelName = string(modelName);
candidate.status = "completed";
candidate.fit.modelName = string(modelName);
candidate.fit.parameters = parameters;
candidate.objective = objective;
candidate.converged = converged;
candidate.parameterCount = numel(parameters);
candidate.errorIdentifier = "";
candidate.errorMessage = "";
end

function candidate = localFailedCandidate(modelName)
candidate.modelName = string(modelName);
candidate.status = "failed";
candidate.fit = struct();
candidate.objective = Inf;
candidate.converged = false;
candidate.parameterCount = NaN;
candidate.errorIdentifier = "synthetic:failure";
candidate.errorMessage = "synthetic failure";
end
