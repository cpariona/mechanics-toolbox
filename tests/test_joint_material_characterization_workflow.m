function tests = test_joint_material_characterization_workflow
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testPublicWorkflowComposesNormalizationSelectionAndExport(testCase)
folder = string(tempname);
cleanup = onCleanup(@() localRemoveFolder(folder)); %#ok<NASGU>
config = localConfig(folder, true);
studies = {
    localStudy("tension", ["t1"; "t2"], 2.4, [17; 29]), ...
    localStudy("compression", "c1", 2.4, 23)};

result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, ["tension"; "compression"], config);

verifyEqual(testCase, result.selectedModelName, "neo-hookean");
verifyEqual(testCase, result.selectedFit.parameters, 2.4, "AbsTol", 1e-5);
verifyEqual(testCase, result.modeSummary.SpecimenCount, [2; 1]);
verifyEqual(testCase, height(result.specimenSummary), 3);
verifyEqual(testCase, result.modeWeights, [0.5; 0.5], "AbsTol", 1e-12);

expected = [
    "candidate_model_summary.csv"
    "selected_joint_parameters.csv"
    "mode_fit_summary.csv"
    "specimen_fit_summary.csv"
    "joint_material_characterization.mat"
    "joint_material_characterization.md"
    "joint_fit_tension.png"
    "joint_fit_tension.fig"
    "joint_fit_compression.png"
    "joint_fit_compression.fig"];
for index = 1:numel(expected)
    verifyTrue(testCase, isfile(fullfile(folder, expected(index))), ...
        "Missing exported file: " + expected(index));
end

candidateSummary = readtable(fullfile(folder, "candidate_model_summary.csv"), ...
    'TextType', 'string');
verifyEqual(testCase, candidateSummary.ModelName, "neo-hookean");
parameters = readtable(fullfile(folder, "selected_joint_parameters.csv"), ...
    'TextType', 'string');
verifyEqual(testCase, string(parameters.Parameter), "mu");
verifyEqual(testCase, parameters.Estimate, 2.4, "AbsTol", 1e-5);
report = string(fileread(fullfile(folder, "joint_material_characterization.md")));
verifyTrue(testCase, contains(report, "Selected model: `neo-hookean`"));
verifyTrue(testCase, contains(report, "independent and unpaired"));

saved = load(fullfile(folder, "joint_material_characterization.mat"));
verifyEqual(testCase, saved.result.selectedModelName, "neo-hookean");
end

function testExportCanRemainDisabled(testCase)
folder = string(tempname);
config = localConfig(folder, false);
studies = {
    localStudy("tension", "t", 1.7, 15), ...
    localStudy("compression", "c", 1.7, 15)};
result = mechanics.workflow.runJointMaterialCharacterization( ...
    studies, ["tension"; "compression"], config);

verifyTrue(testCase, isempty(fieldnames(result.outputFiles)));
verifyFalse(testCase, isfolder(folder));
end

function testExporterRejectsIncompleteResults(testCase)
folder = string(tempname);
verifyError(testCase, @() mechanics.io.exportJointMaterialCharacterization( ...
    struct(), folder), "mechanics:io:InvalidJointMaterialCharacterization");
end

function config = localConfig(folder, exportEnabled)
config = mechanics.config.jointMaterialCharacterizationConfig();
config.candidateModelNames = "neo-hookean";
config.selection.tieBreakOrder = "neo-hookean";
config.fitting.initialGuess = 1;
config.fitting.numberOfStarts = 3;
config.fitting.randomSeed = 9;
config.fitting.maxIterations = 1500;
config.fitting.maxFunctionEvaluations = 4000;
config.export.enabled = exportEnabled;
config.export.outputFolder = folder;
end

function study = localStudy(mode, specimenIds, mu, pointCounts)
specimenIds = string(specimenIds(:));
pointCounts = pointCounts(:);
if isscalar(pointCounts)
    pointCounts = repmat(pointCounts, numel(specimenIds), 1);
end
records = repmat(localRecord(mode, "", mu, pointCounts(1)), ...
    numel(specimenIds), 1);
for index = 1:numel(specimenIds)
    records(index) = localRecord(mode, specimenIds(index), mu, pointCounts(index));
end
study.analysis.records = records;
study.analysis.summary = table(specimenIds, repmat("processed", numel(specimenIds), 1), ...
    'VariableNames', {'SpecimenId','Status'});
study.populationStatus = "completed";
study.config = struct();
end

function record = localRecord(mode, specimenId, mu, pointCount)
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
if mode == "tension"
    deformation = linspace(0, 0.75, pointCount)';
else
    deformation = linspace(0, -0.32, pointCount)';
end
stress = mechanics.models.evaluateModel("neo-hookean", deformation, mu, context);
processed.strain = deformation;
processed.stress = stress;
processed.units.strain = "1";
processed.units.stress = "MPa";
processed.mechanicsConfig.strainMeasure = "engineering";
processed.mechanicsConfig.stressMeasure = "engineering";
specimen.id = string(specimenId);
specimen.testType = string(mode);
specimen.processed = processed;
record.index = 1;
record.specimenId = string(specimenId);
record.sheetName = string(specimenId);
record.status = "processed";
record.quality = struct();
record.specimen = specimen;
record.errorIdentifier = "";
record.errorMessage = "";
record.group = "";
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
