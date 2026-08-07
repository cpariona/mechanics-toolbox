function tests = test_tensile_application_range_workflow
tests = functiontests(localfunctions);
end

function setupOnce(~)
startup;
end

function testPublicWorkflowComposesMaintainedStages(testCase)
config = localConfig();
tensileStudy = localStudy("tension", ["t1"; "t2"], 0.4, 61);
original = tensileStudy;
result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);

verifyEqual(testCase, result.selectedModelName, "neo-hookean");
verifyEqual(testCase, result.referenceProperties.names, "mu0");
verifyEqual(testCase, result.referenceProperties.values, 0.4, ...
    "AbsTol", 2e-3);
verifyEqual(testCase, result.rangeSensitivity.completedScenarioCount, 3);
verifyFalse(testCase, result.hasCompressionValidation);
verifyEmpty(testCase, fieldnames(result.compressionValidation));
verifyEqual(testCase, tensileStudy, original);
end

function testOptionalCompressionAndExportAreIntegrated(testCase)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() localRemoveFolder(folder)); %#ok<NASGU>
config = localConfig();
config.export.enabled = true;
config.export.outputFolder = folder;
tensileStudy = localStudy("tension", ["t1"; "t2"], 0.4, 61);
compressionStudy = localStudy("compression", ["c1"; "c2"], 0.4, 51);

result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config, compressionStudy);

verifyTrue(testCase, result.hasCompressionValidation);
verifyFalse(testCase, result.compressionValidation.refitPerformed);
verifyLessThan(testCase, result.compressionValidation.meanRMSE, 1e-10);
requiredFiles = ["candidateSummary", "selectedParameters", ...
    "referenceProperties", "tensileSpecimenSummary", ...
    "rangeSensitivitySummary", "compressionValidationSummary", ...
    "result", "report"];
verifyTrue(testCase, all(isfield(result.outputFiles, requiredFiles)));
for index = 1:numel(requiredFiles)
    verifyTrue(testCase, isfile(result.outputFiles.(requiredFiles(index))));
end
reportText = string(fileread(result.outputFiles.report));
verifyTrue(testCase, contains(reportText, "Selected model: `Neo-Hookean`"));
verifyTrue(testCase, contains(reportText, "Refitting performed: `false`"));
end

function testSecondOrderYeohExportAndPersistence(testCase)
folder = string(tempname);
mkdir(folder);
cleanup = onCleanup(@() localRemoveFolder(folder)); %#ok<NASGU>
parameters = [0.05, 0.012];
config = localConfig();
config.candidateModelNames = "yeoh-second-order";
config.selection.tieBreakOrder = "yeoh-second-order";
config.export.enabled = true;
config.export.outputFolder = folder;
config.fitting.numberOfStarts = 8;
tensileStudy = localModelStudy( ...
    "tension", ["y1"; "y2"], "yeoh-second-order", parameters, 71);

result = mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    tensileStudy, config);

verifyEqual(testCase, result.selectedModelName, "yeoh-second-order");
verifyEqual(testCase, result.selectedFit.parameterNames, ["C10", "C20"]);
verifyEqual(testCase, result.referenceProperties.names, "mu0");
verifyEqual(testCase, result.referenceProperties.values, 2 * parameters(1), ...
    "RelTol", 2e-3);

selectedParameters = readtable(result.outputFiles.selectedParameters, ...
    'TextType', 'string');
verifyEqual(testCase, selectedParameters.Parameter, ["C10"; "C20"]);
verifyEqual(testCase, selectedParameters.Estimate, parameters(:), ...
    "RelTol", 2e-2, "AbsTol", 2e-5);
reportText = string(fileread(result.outputFiles.report));
verifyTrue(testCase, contains(reportText, ...
    "Selected model: `Yeoh second order`"));
verifyTrue(testCase, contains(reportText, "Yeoh second order"));
saved = load(result.outputFiles.result);
verifyEqual(testCase, saved.result.selectedModelName, "yeoh-second-order");
verifyEqual(testCase, saved.result.selectedFit.parameterNames, ["C10", "C20"]);
end

function testEnabledExportRequiresOutputFolder(testCase)
config = localConfig();
config.export.enabled = true;
config.export.outputFolder = "";
verifyError(testCase, @() mechanics.workflow.runTensileApplicationRangeCharacterization( ...
    localStudy("tension", ["t1"; "t2"], 0.4, 41), config), ...
    "mechanics:workflow:MissingTensileApplicationRangeOutputFolder");
end

function config = localConfig()
config = mechanics.config.tensileApplicationRangeCharacterizationConfig();
config.fitRange = [0, 0.30];
config.rangeSensitivity.maximumDeformations = [0.10; 0.20; 0.30];
config.candidateModelNames = "neo-hookean";
config.selection.tieBreakOrder = "neo-hookean";
config.minimumObservationsPerSpecimen = 8;
config.minimumSpecimens = 2;
config.fitting.numberOfStarts = 3;
config.fitting.randomSeed = 7;
config.export.enabled = false;
end

function study = localStudy(mode, specimenIds, mu, pointCount)
study = localModelStudy(mode, specimenIds, "neo-hookean", mu, pointCount);
end

function study = localModelStudy(mode, specimenIds, modelName, parameters, pointCount)
specimenIds = string(specimenIds(:));
records = repmat(localModelRecord( ...
    mode, "", modelName, parameters, pointCount), numel(specimenIds), 1);
for index = 1:numel(specimenIds)
    records(index) = localModelRecord( ...
        mode, specimenIds(index), modelName, parameters, pointCount);
    records(index).index = index;
end
study.sourceFile = "synthetic.xlsx";
study.sourceFiles = "synthetic.xlsx";
study.analysis.records = records;
study.populationStatus = "completed";
study.config = struct();
study.provenance.inputType = "synthetic";
study.createdAt = datetime(2026, 8, 2);
end

function record = localModelRecord(mode, specimenId, modelName, parameters, pointCount)
if mode == "tension"
    deformation = linspace(0, 0.30, pointCount)';
else
    deformation = linspace(0, -0.25, pointCount)';
end
context.deformationMeasure = "engineering-strain";
context.stressMeasure = "nominal";
stress = mechanics.models.evaluateModel(modelName, deformation, parameters, context);
specimen.id = string(specimenId);
specimen.processed.strain = deformation;
specimen.processed.stress = stress;
specimen.processed.units.strain = "1";
specimen.processed.units.stress = "MPa";
specimen.processed.mechanicsConfig.strainMeasure = "engineering";
specimen.processed.mechanicsConfig.stressMeasure = "engineering";
record.index = 1;
record.specimenId = string(specimenId);
record.sheetName = "Sheet-" + specimenId;
record.status = "processed";
record.specimen = specimen;
record.errorIdentifier = "";
record.errorMessage = "";
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
